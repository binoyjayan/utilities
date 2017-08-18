#!/usr/bin/python
#
# Script to find difference between defconfig files
#
# CONFIGs present in first defconfig file (given as argument) but absent in the
# second file is prefixed with a '-' sign in the output. Similarly, CONFIGs
# present in the second defconfig file but absent in first file1 is prefixed
# with a '+' sign in the output.
#
import sys
import re
import os

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

        # If the config line1 is not present in arr2
        if not find_config(config1, arr2):
            print prefix, line

# Main script begins here
bname=os.path.basename(sys.argv[0])
if len(sys.argv) < 3:
    print "\nUsage: " 
    print bname + " <defconfig1> <defconfig2>\n"
    print "Example: " 
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig"
    print bname + " msm-auto_defconfig msm-auto-gvm_defconfig > d.def"
    print "" 
    sys.exit(1)

cfg1 = loadf(sys.argv[1])
cfg2 = loadf(sys.argv[2])

iterate_configs(cfg1, cfg2, "-")
iterate_configs(cfg2, cfg1, "+")

