#!/usr/bin/python
import sys
import time
import termios

ABORT_TIMEOUT = 3
ABORT_CHARS = 'aa'

print("Press 'aa' to abort installation\n")
# The standard IO is the terminal /dev/pts/0
fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
new = termios.tcgetattr(fd)
new[3] = new[3] & ~termios.ECHO & ~termios.ICANON
new[6][termios.VMIN] = 0
exit_code = 0

try:
    print("Changing terminal settings")
    termios.tcsetattr(fd, termios.TCSADRAIN, new)
    for i in range(0, ABORT_TIMEOUT):
        try:
            input_data = raw_input()
            print("Input keystrokes: {}".format(input_data))
        except Exception:
            input_data = ''
        if input_data.startswith(ABORT_CHARS):
            print("Installation aborted by user")
            exit_code = 1
            break
        time.sleep(1)
except Exception as e:
    print("Failed to change terminal settings:{}".format(str(e)))
    exit_code = 0
finally:
    print("Reset terminal settings")
    termios.tcsetattr(fd, termios.TCSADRAIN, old)

print("Exit:{}".format(exit_code))
sys.exit(exit_code)
