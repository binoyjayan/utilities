import sys
import os
from subprocess import Popen, PIPE
import re
import select

DEBUG = False
PROMPT = '(gdb) '

class Gdb(Popen):
  """
  A subprocess of subprocess.Popen which interacts with gdb.
  """
  
  def __init__(self, hide_stderr=False):
    stderr_file = open('/dev/null','w') if hide_stderr else None
    Popen.__init__(self, ['gdb'],
                   stdin=PIPE, stdout=PIPE, stderr=stderr_file)

    self._buffer = ''
    self.read_until_prompt()
    
    self.cmd('set print elements 0')
    self.cmd('set width 0')
  
  def read_until_prompt(self, timeout=None):
    """
    Read until prompt.
    If timeout is given, if after 'timeout' seconds there was no prompt,
    return None.
    """
    while not (self._buffer == PROMPT or self._buffer.endswith('\n'+PROMPT)):
      if timeout:
        if not select.select([self.stdout], [], [], timeout)[0]:
          return None
      read = os.read(self.stdout.fileno(), 8192)
      if DEBUG:
        sys.stderr.write(read)
      self._buffer += read
    r = self._buffer[:-len(PROMPT)]
    self._buffer = ''
    return r

  def cmd(self, cmd, timeout=None):
    """
    Execute cmd and return the output.
    If timeout is given, return None if 
    """
    if not cmd.endswith('\n'):
      cmd += '\n'
    if DEBUG:
      sys.stderr.write(cmd)
    self.stdin.write(cmd)
    return self.read_until_prompt(timeout=timeout)

def get_call_stack(gdb):
  """ get the call stack of a 32b x86 core without relying on %ebp, assuming GNU prologue & epilogue code """
  addr=int(gdb.cmd('p /x $pc').split()[-1],16)
  funcre=re.compile('Dump of assembler code for function (.*):')
  spsetupre=re.compile('.*sub[ ]*\\$0x([A-Fa-f0-9]+),%esp')
  pushargre=re.compile('.*push[ ]*%')
  offset = 0
  stack = []
  while True:
    code = gdb.cmd('disass 0x%x'%(addr))
    # we need to find out the stack space reserved for keeping local variables and arguments.
    # gcc saves arguments with push instructions, then allocates locals with sub sz,%esp.
    locals = 0 # bytes
    args = 0 # bytes
    func = None
    for line in code.split('\n'):
      m=funcre.match(line)
      if m:
        func = m.groups()[0]
      else:
        m=pushargre.match(line)
        if m:
          args += 4 # assuming 32b regs
        m=spsetupre.match(line)
        if m:
          locals = int(m.groups()[0],16)
          break # from this point, %esp is left alone until the epilogue
  
    if func == None:
      return stack # gdb refuses to disassemble without symbolic information, so we can't get past
      # return addresses with no syminfo
  
    stack.append((func,addr,locals,args))
    offset += locals + args
    addr = int(gdb.cmd('p /x *(int*)($esp + %d)'%offset).split()[2],16) # gdb returns "$i = 0x..."
    offset += 4 # 4b for keeping the return address
      
gdb = Gdb(hide_stderr=True)
gdb.cmd('file '+sys.argv[1])
gdb.cmd('core-file '+sys.argv[2])

stack = get_call_stack(gdb)
for func,addr,locals,args in stack:
    print '[locals: %03d, args: %02d] 0x%08x'%(locals,args,addr),func

