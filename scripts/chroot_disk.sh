#!/bin/bash

BASESTR=`basename $0`
IMG=cstor10-installer-1804.img
MOUNTDIR=/mnt/disk
BLOCK=2048
BS=512
OFFSET=`expr $BLOCK \* $BS`
UMOUNTFLAG=false
DNSFLAG=false
DNS=/etc/resolv.conf
HELPFLAG=false

usage()
{
      echo ""
      echo "Usage: $BASESTR <option> [parameter] [option2] [param2]..."
      echo ""
      echo "Options"
      echo ""
      echo "-f image   : Device name. Default: $IMG"
      echo "-d dir     : mount directory. Default: $MOUNTDIR"
      echo "-o offset  : Offset on device to mount from. Default: $OFFSET"
      echo "-u         : unmount all directories on chroot-ed filesystem"
      echo "-D         : Copy the host dns settings"
      echo "-h         : Display usage"
      echo ""
      echo "Examples:"
      echo ""
      echo "$BASESTR"
      echo "$BASESTR -f disk.img"
      echo "$BASESTR -f disk.img -o $OFFSET"
      echo "$BASESTR -f disk.img -o $OFFSET -d /mnt/rootdisk"
      echo ""
}

check_su()
{
	ME=`whoami`
	if [ $ME != "root" ]; then
		echo "Run the script as a root"
		echo ""
		exit
	fi
}

# Main script execution
echo ""
while getopts "f:d:o:uDh" opt; do
  case $opt in
    f)
        IMG=$OPTARG
        ;;
    d)
        MOUNTDIR=$OPTARG
        ;;
    o)
        OFFSET=$OPTARG
        ;;
    u)
        UMOUNTFLAG=true
        ;;
    D)
	DNSFLAG=true
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

check_su

if [ ! -f "$IMG" ]; then
	echo "please specify a valid image file using option -f"
	exit
fi

DNS_CURR=${MOUNTDIR}${DNS}
DNS_ORIG=${MOUNTDIR}${DNS}.orig

if [ "$UMOUNTFLAG" == "false" ]; then
	if mountpoint "$MOUNTDIR" 2>&1 > /dev/null; then
        	echo "$MOUNTDIR is already mounted. Please unmount or use another directory"
		exit
	fi

	echo "Mounting file system on [ $IMG ] at offset $OFFSET" at "$MOUNTDIR"

	mkdir -p $MOUNTDIR

	mount -o loop,offset=$OFFSET $IMG $MOUNTDIR
	mount -t proc proc   ${MOUNTDIR}/proc
	mount -t sysfs sys   ${MOUNTDIR}/sys
	mount -t tmpfs tmpfs ${MOUNTDIR}/tmp
	mount -o bind /dev   ${MOUNTDIR}/dev

	if [ "$DNSFLAG" == "true" ]; then
		echo "Copying DNS settings [ backup: $DNS_ORIG ]..."
		mv ${MOUNTDIR}${DNS} ${MOUNTDIR}${DNS}.orig
		cp -L $DNS ${MOUNTDIR}${DNS}
	fi

	echo ""
	echo "Run the following command to enter chroot session"
	echo "Type exit when finished and use the option -u to unmount all directories"
	echo ""
	echo "chroot ${MOUNTDIR} /bin/bash"
	echo ""
else
	if [ "$DNSFLAG" == "true" ]; then
		if [ ! -f "${MOUNTDIR}${DNS}.orig" ]; then
			echo "No DNS restore file found"
		else
			echo "Restoring DNS settings from $DNS_ORIG..."
			rm ${MOUNTDIR}${DNS}
			mv ${MOUNTDIR}${DNS}.orig ${MOUNTDIR}${DNS}
		fi
	fi

	echo "unmounting..."

	umount ${MOUNTDIR}/dev
	umount ${MOUNTDIR}/tmp
	umount ${MOUNTDIR}/sys
	umount ${MOUNTDIR}/proc
	umount ${MOUNTDIR}
fi


