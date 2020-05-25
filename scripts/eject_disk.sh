#!/bin/bash

# Eject a disk

BASESTR=`basename $0`
usage()
{
	echo ""
	echo "Usage:"
	echo ""
	echo "$BASESTR </dev> : Eject disk"
	echo ""
	echo "Example:"
	echo "$BASESTR /dev/sdd"
	echo ""
}

if [ "$1" == "" ]
then
	usage
	exit
fi

LABEL=`basename $1`
DEVICE="/dev/${LABEL}"

echo "Flusing buffers on $DEVICE"
blockdev --flushbufs ${DEVICE}

CMD="echo 1 > /sys/block/${LABEL}/device/delete"
echo "Ejecting $DEVICE [ $CMD ]..."
eval ${CMD}

echo "To reattach disks, run:"
echo "echo '- - -' > /sys/class/scsi_host/host10/scan"

