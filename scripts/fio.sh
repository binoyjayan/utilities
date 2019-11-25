#!/bin/bash
###########################################################################
#                                                                         #
#     Author: Binoy Jayan                                                 #
#     Date Written : November 20 2019                                     #
#                                                                         #
#     Description                                                         #
#     ------------                                                        #
#     fio.sh : fio sequential test script                                 #
#                                                                         #
#     For options run the following command                               #
#                                                                         #
#        fio.sh -h                                                        #
#                                                                         #
###########################################################################

# Default options; Can be changed at run time using cmdline options
BASESTR=`basename $0`
TEST=read_capture
ENG=libaio
DEV=/dev/zero
IODEP=256
OFF=0
FILESIZE=1Gi
BLKSIZE=256Ki
PERCENT=100
JOBS=1
ZONESZ=10240 #Size in MiB
HELPFLAG=false
EXE=false
CSV=test.csv

usage()
{
      echo ""
      echo "Usage: $BASESTR <option> [parameter] [option2] [param2]..."
      echo ""
      echo "Options"
      echo ""
      echo "-d dev name     : Device name. Default: $DEV"
      echo "-i iodepth      : IO depth. Default: $IODEP"
      echo "-s filesize     : size of read/write region in zone [with units]. Default: $FILESIZE"
      echo "-b blksize      : block size [ with units ]. Default: $BLKSIZE"
      echo "-r read percent : Read percentage. Default: $PERCENT"
      echo "-j jobs         : Number of jobs. Default: $JOBS"
      echo "-j zone sz      : Size of a zone [ in units of MiB). Default: $ZONESZ"
      echo "-o csv          : csv output. Default: $CSV"
      echo "-y              : Execute"
      echo "-h              : Display usage"
      echo ""
      echo "EXamples:"
      echo ""
      echo "$BASESTR"
      echo "$BASESTR -d /dev/capturea -z $ZONESZ -r 100 -o real_100.log"
      echo "$BASESTR -d /dev/capturea -z $ZONESZ -r 100 -o real_100.log -y"
      echo ""
}

check_su()
{
	ME=`whoami`
	if [ $ME != "root" ]; then
		echo "Run the script as a root or use sudo $BASESTR"
		echo ""
		exit
	fi
}


test_fio()
{
    CMD="fio --name=$TEST --filename=$DEV --direct=1 --ioengine=$ENG --iodepth=$IODEP
             --offset=${OFF}Mi --offset_align=$BLKSIZE  --size=$FILESIZE --bs=$BLKSIZE \
             --rw=rw --rwmixread=$PERCENT --numjobs=$JOBS"
    if [ "$EXE" == true ]; then
        OUT=`$CMD`
        RRATE=`echo $OUT | awk -F "READ: bw=" '{ print $2 }' | awk -F "MiB" '{ print $1}'`
        WRATE=`echo $OUT | awk -F "WRITE: bw=" '{ print $2 }' | awk -F "MiB" '{ print $1}'`
        echo "Rate: read: $RRATE, write: $WRATE"

        echo "$1,$OFF,$RRATE,$WRATE" >> $CSV
        # Time for the device to breathe
	sleep 1
    else
        echo $CMD
    fi
    echo ""
}

fio_mix_reads()
{
    STARTDATE=`date`
    STARTSEC=`date +"%s"`

    echo ""
    if [ ! -b $DEV ]; then
	echo "Specify a valid block device using -d switch"
        echo ""
	exit
    fi

    echo "Retrieving disk size.."
    TOTAL=`blockdev --getsize64 $DEV`
    # convert to MiB
    TOTAL=`expr $TOTAL / 1024 / 1024`
    SZ=`expr $TOTAL / 1000`

    echo ""
    echo "Disk size: $TOTAL MiB. Zone size: $ZONESZ MiB [ suggested: $SZ MiB ]"
    echo ""

    echo "SN,Offset (MiB),Read rate(MiB/s),Write rate(MiB/s)" > $CSV

    i=1
    OFF=0
    TOTAL=`expr $TOTAL - $ZONESZ`

    while [ $OFF -le $TOTAL ]
    do
        echo "$i. Read $FILESIZE bytes at $OFF Mi"
        test_fio $i
        OFF=`expr $OFF + $ZONESZ`
        i=`expr $i + 1`
    done

    echo ""

    ENDSEC=`date +"%s"`
    ENDDATE=`date`

    echo "Tests started at $STARTDATE and ended at $STARTDATE"
    TIMEDIFF=`expr $ENDSEC - $STARTSEC`
    MIN=`expr $TIMEDIFF / 60`
    SEC=`expr $TIMEDIFF % 60`
    echo "Elapsed time = $MIN minutes $SEC seconds"
    echo ""
}

# Main script execution
echo ""

found=0
while getopts "d:i:s:b:r:j:z:o:yh" opt; do
  found=1
  case $opt in
    d)
        DEV=$OPTARG
        ;;
    i)
        IODEP=$OPTARG
        ;;
    s)
        FILESIZE=$OPTARG
        ;;
    b)
        BLKSIZE=$OPTARG
        ;;
    r)
        PERCENT="$OPTARG"
        ;;
    j)
        JOBS="$OPTARG"
        ;;
    z)
        ZONES="$OPTARG"
        ;;
    o)
        CSV="$OPTARG"
        ;;
    y)
	EXE=true
        ;;
    h)
	HELPFLAG=true
        ;;
    \?)
	    echo ""
        echo "Invalid/insufficient arguments mentioned!"
        usage
	exit
        ;;
  esac
done

if [ "$HELPFLAG" == "true" ]; then
	usage
	exit
fi

if [ "$ECHO" == "" ]; then
	check_su
fi

fio_mix_reads

