#!/usr/bin/python

import sys

if len(sys.argv) < 3:
   print "Usage: " 
   print sys.argv[0] + " <public key ascii file> <public key hex output>"
   sys.exit(1)


f1 = open(sys.argv[1], 'rb')
f2 = open(sys.argv[2], 'wb')

line = f1.readline()
if line.find("-----BEGIN ") >= 0:
    print "Removing begin of key text..."

f2.write("const char key[] = {\n")

count = 0
tcount = 0
for line in f1:
    sline = line.rstrip('\n')
    if line.find("-----END ") >= 0:
	print "Reached End of key..."
	break
    print sline

    for c in sline:
        f2.write(hex(ord(c)) + ", ")
	count += 1
	tcount += 1
        if count > 11:
            count = 0
            f2.write("\n")


f2.write("\n};\n")

print "Keysize = " , tcount , "bytes"
f2.write("// Keysize = %d bytes\n" % tcount);

f1.close()
f2.close()

