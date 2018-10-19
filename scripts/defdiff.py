#!/usr/bin/python
#
# Script to find difference between defconfig files
#
# CONFIGs present in first defconfig file (given as argument) but absent in the
# second file is prefixed with a '-' sign in the output. Similarly, CONFIGs
# present in the second defconfig file but absent in first file1 is prefixed
# with a '+' sign in the output. Alternatively, the CONFIGs can be displayed
# without the prefix as well.
#
import sys
import re
import os

def usage():
    bname=os.path.basename(sys.argv[0])
    print "\nUsage:"
    print bname + " <defconfig1> <defconfig2> [--no-prefix | -n ]\n"
    print "Examples:"
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig"
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig -n"
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig --no-prefix"
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig > diff.def"
    print ""

# Load file into an array of strings
def loadf(filen):
    f = open(filen, 'rb')
    lines = [x.strip('\n') for x in f.readlines()]
    f.close()
    return lines

# Return a duplet config 'CONFIG_XX=Y'
def getconf(str):
    mo = re.match("(CONFIG_[A-Za-z0-9_]+)=(.*)", str)
    if not mo:
        return None
    return mo.groups()

# Find the config duplet in the array of configs 'lines'
def find_config(conf1, lines):
    for line in lines:
        conf2 = getconf(line)
        if conf2:
            if conf1[0] == conf2[0] and conf1[1] == conf2[1]:
                return True
    return False

def iterate_configs(arr1, arr2, prefix):
    for line in arr1:
        config1 = getconf(line)
        if not config1:
            continue

        # If the config config1 is not present in arr2
        if not find_config(config1, arr2):
            if prefix:
                print prefix, line
            else:
                print line

# Function to display headers
def disp_header(f1, f2):
    print ""
    print "================================================================"
    print " CONFIGs present in", f1, "but absent in", f2
    print "================================================================"

# Main script begins here
if len(sys.argv) < 3 or len(sys.argv) > 4:
    usage()
    sys.exit(1)


if not os.path.isfile(sys.argv[1]):
    print "File", sys.argv[1], "not found!"
    sys.exit(1)

if not os.path.isfile(sys.argv[2]):
    print "File", sys.argv[2], "not found!"
    sys.exit(1)

no_prefix = False
if len(sys.argv) == 4:
    if sys.argv[3] == "-n" or sys.argv[3] == "--no-prefix":
        no_prefix = True
    else:
        print "\nInvalid argument:", sys.argv[3]
        usage()
        sys.exit(1)

cfg1 = loadf(sys.argv[1])
cfg2 = loadf(sys.argv[2])

arg1 = os.path.basename(sys.argv[1])
arg2 = os.path.basename(sys.argv[2])

if no_prefix:
    disp_header(arg1, arg2);
    iterate_configs(cfg1, cfg2, None)
    disp_header(arg1, arg2);
    iterate_configs(cfg2, cfg1, None)
else:
    iterate_configs(cfg1, cfg2, "-")
    iterate_configs(cfg2, cfg1, "+")

