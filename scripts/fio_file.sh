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
ENG=libaio
FILE="/tmp/test"
SIZE="1Gi"
IODEP=128
BLKSIZE=128Ki
PERCENT=100
JOBS=1
TIME=1m
LOGD=/tmp/fio_logs
EXE=false
HELPFLAG=false

usage()
{
      echo ""
      echo "Usage: $BASESTR [option] [param]"
      echo ""
      echo "Options"
      echo ""
      echo "-f file         : File /device to test. Default: $FILE"
      echo "-s sz           : Size to test. Default: $SIZE"
      echo "-i iodepth      : IO depth. Default: $IODEP"
      echo "-b blksize      : block size. Default: $BLKSIZE"
      echo "-r read percent : Read percentage. Default: $PERCENT"
      echo "-j jobs         : Number of jobs. Default: $JOBS"
      echo "-t time         : Runtime. Default: $TIME"
      echo "-l logdir       : Log directory. Default: $LOGD"
      echo "-y              : Execute test"
      echo "-h              : Display usage"
      echo ""
      echo "Examples:"
      echo ""
      echo "$BASESTR"
      echo "$BASESTR -f /dev/sdb -y"
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

fio_test_file()
{
    NAME=`basename $FILE`
    LOG_FIO="${LOGD}/${NAME}_fio.log"
    LOG_DISK="${LOGD}/${NAME}_iostat_disk.log"
    LOG_CPU="${LOGD}/${NAME}_iostat_cpu.log"

    CMD_DISK="iostat -d 1 $DEV"
    CMD_CPU="iostat -c 1"
    CMD_FIO="fio --filename=$FILE --size=$SIZE --direct=1 --rw=randrw --rwmixread=$PERCENT
        --ioengine=libaio --bs=$BLKSIZE --iodepth=$IODEP --numjobs=$JOBS --time_based
        --runtime=$TIME --group_reporting --name=test_$FILE"

    # echo "FIO log         : $LOG_FIO"
    # echo "IOSTAT disk log : $LOG_DISK"
    # echo "IOSTAT cpu log  : $LOG_CPU"

    if [ "$EXE" == true ]; then
        echo "Monitoring disk - $CMD_DISK"
        $CMD_DISK > $LOG_DISK &
        echo "Monitoring cpu - $CMD_CPU"
        $CMD_CPU > $LOG_CPU &
        echo "Running test..."
        $CMD_FIO > $LOG_FIO
        RRATE=`grep "READ:"  $LOG_FIO`
        WRATE=`grep "WRITE:" $LOG_FIO`
        pkill iostat
        sleep 1
        pkill -9 iostat
        echo "Transfer Rate:"
        echo $RRATE
        echo $WRATE
    else
        echo $CMD_DISK
        echo $CMD_CPU
        echo $CMD_FIO
    fi
}

fio_mix_reads()
{
    # create log directory
    if [ -e $LOGD ]; then
        if [ ! -d $LOGD ]; then
            echo "$LOGD is not a directory"
            exit
        fi
    else
        echo "creating log directory $LOGD..."
        mkdir -p $LOGD
    fi

    # Find the device name where the file is located
    if [ -b $FILE ]; then
        DEV=$FILE
    else
        DIR=`dirname $FILE`
        DEV=`df $DIR | tail -1 | awk '{print $1}'`
    fi

    STARTDATE=`date`
    STARTSEC=`date +"%s"`

    fio_test_file

    ENDSEC=`date +"%s"`
    ENDDATE=`date`

    if [ "$EXE" == true ]; then
        echo ""
        echo "Tests started at $STARTDATE and ended at $STARTDATE"
        TIMEDIFF=`expr $ENDSEC - $STARTSEC`
        MIN=`expr $TIMEDIFF / 60`
        SEC=`expr $TIMEDIFF % 60`
        echo "Elapsed time = $MIN minutes $SEC seconds"
        echo ""
    else
        echo ""
        echo "Provide option -y to run test"
        echo ""
    fi
}

# Main script execution
echo ""

found=0
while getopts "f:s:b:i:r:j:t:l:yh" opt; do
  found=1
  case $opt in
    f)
        FILE=$OPTARG
        ;;
    s)
        SIZE=$OPTARG
        ;;
    b)
        BLKSIZE=$OPTARG
        ;;
    i)
        IODEP=$OPTARG
        ;;
    r)
        PERCENT="$OPTARG"
        ;;
    j)
        JOBS="$OPTARG"
        ;;
    t)
        TIME="$OPTARG"
        ;;
    l)
        LOGD="$OPTARG"
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

shift $(($OPTIND - 1))
fio_mix_reads $*

