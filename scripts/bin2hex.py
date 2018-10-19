#!/usr/bin/python

import sys

if len(sys.argv) < 3:
   print "Usage: " 
   print sys.argv[0] + " <binary file> <hex output file>"
   sys.exit(1)


f1 = open(sys.argv[1], 'rb')
f2 = open(sys.argv[2], 'wb')

f2.write("const char key[] = {\n")

count = 0
tcount = 0

byte = "x"
while byte != "":
    byte = f1.read(1)
    if byte == "":
	break
    count += 1
    tcount += 1
    f2.write("0x%.2x, " % ord(byte))
    if count > 11:
        count = 0
        f2.write("\n")

f2.write("\n};\n")

print "Keysize = " , tcount , "bytes"
f2.write("// Keysize = %d bytes\n" % tcount);

f1.close()
f2.close()

