#!/usr/bin/python
#
# Script to exclude configuration items from kernel defconfig files
# The items to be excluded is read from another file
# Changes are written to the output file
#
import sys
import re
import os

bname=os.path.basename(sys.argv[0])
if len(sys.argv) < 4:
   print "\nUsage: " 
   print bname + " <defconfig> <exclude config> <output file>\n"
   print "Example: " 
   print bname + " msm-auto_defconfig  exclude.def out.def\n"
   sys.exit(1)


f1 = open(sys.argv[1], 'rb')
f2 = open(sys.argv[2], 'rb')
f3 = open(sys.argv[3], 'wb')

str=f2.read()

for rline in f1:
    line = rline.rstrip('\n')
    # print line

    mo=re.match("^#.*", line)
    if mo:
        print "Writing commented line.", line
        f3.write(rline)
    else:
        mo=re.match("(CONFIG_[A-Za-z0-9_]+)=.*", line)
	if mo:
            if mo.groups()[0] in str:
                 print "Removing ", mo.groups()[0]
            else:
                print "Adding ", mo.groups()[0]
                f3.write(rline)
        else:
            print line, " not found in list of removal configs" 

f1.close()
f2.close()
f3.close()

