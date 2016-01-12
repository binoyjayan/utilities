#!/usr/bin/python
#
# Script to parse output of the following command for an average of n counts
# 
# adb shell cat /sys/bootkpi/kpi_values
# The command above is used to retrieve kpi values from target
#
# Sample usage:
#
# adb shell cat /sys/bootkpi/kpi_values >> kpi.log
# adb reboot
# adb shell cat /sys/bootkpi/kpi_values >> kpi.log
# adb reboot
# adb shell cat /sys/bootkpi/kpi_values >> kpi.log
# adb reboot
# adb shell cat /sys/bootkpi/kpi_values >> kpi.log
# adb reboot
#
# kpiavg kpi.log
#

import sys

kpimark = [
    "Splash Screen",
    "Linux_Kernel-Start",
    "rvc thread enabled",
    "RVC swprobe",
    "KGSL_Init - Start",
    "KGSL_Init - End",
    "Linux_Kernel - End",
    "SF_Init - Start",
    "KGSL first submit",
    "BootAnim - Start",
    "SF_Init - End",
    "MediaServer - Start",
    "NativeHMI - Start",
    "EarlyAudio Start",
    "Zygote - Start",
    "SystemServer - Star",
    "LocationManager",
    "HMIHome - Start",
    "BootAnim - End",
    "Boot completed"
]

kpilen = len(kpimark)

count = [0] * kpilen
kpi   = [0.0] * kpilen


if len(sys.argv) < 2:
   print "Usage: " 
   print sys.argv[0] + " <kpi dump file>"
   sys.exit(1)


print "Parsing kpi data in '" + sys.argv[1] + "'..."
f1 = open(sys.argv[1], 'rb')

for line in f1:
    sline = line.rstrip('\n')
    i = 0
    for km in kpimark:
	off = sline.find(km)
        if off >= 0:
            off += len(km)
            val = sline[off:]
            val = val.lstrip(": \t")
            off = val.find(" ")
            if off >= 0:
                val = val[0:off]
            # print "Found "+ km + " Occurances:" + str(len(val)) + " VAL:" + val + " LEN: " + str(len(val))
            if len(val) >= 1:
               kpi[i] += float(val)
            count[i] += 1
            break
        i += 1
print "done"

print "-------------------------------------------------------------------"
print "               Average kpi values"
print "-------------------------------------------------------------------"

tot = 0.0
for i in xrange(0, kpilen):
    if count[i] > 0:
        kpi[i] = kpi[i] / count[i]
    print (kpimark[i] + "\t\t : " + str(kpi[i]) + " seconds ["  + str(count[i]) + " occurances]").expandtabs(10)
    tot += kpi[i]

print "-------------------------------------------------------------------"

f1.close()

