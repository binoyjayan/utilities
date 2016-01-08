#!/bin/bash

BASESTR=`basename $0`
ROOTDIR=`readlink -m .`
ROOTFS_IMG=`readlink -m initrd.img`
TARTMP=/tmp/__tar_temp_dir__
#FSSIZE=300M
FSSIZE=50M

if [ "$#" -lt 1 ]
then
        echo ""
        echo "Usage : $BASESTR <initrd vanilla img> [output image name]"
        echo ""
        echo "  rootfs vanilla img     : Should be in tar.gz format"
        echo "  output image name      : Name of the output rootfs image in ext4 format (optional)"
        echo "                           Default Value is $ROOTFS_IMG"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR initrd_vanilla.tar.bz2 $ROOTFS_IMG"
        echo " $BASESTR initrd_vanilla.tar.bz2"
        echo ""
        exit
fi

echo -n "Validating rootfs directory..."
if [ ! -f "$1" ]
then
        echo "The rootfs image file '$1' was not found"
        exit
fi

echo "done."

if [ "$2" != "" ]
then
        ROOTFS_IMG=`readlink -m $2`
fi

echo "Using initrd output image - $ROOTFS_IMG"

ROOTFS_TAR=`readlink -m $1`

STARTDATE=`date`
STARTSEC=`date +"%s"`

echo -n "Creating temporary working directory to extract image..."
mkdir -p $TARTMP
echo "done."

echo -n "Extracting vanilla kernel to temporary directory..."
rm -rf $TARTMP/*
cd $TARTMP 
tar xf $ROOTFS_TAR
cd - &> /dev/null
echo "done."

echo "Creating cpio archive..."
cd $TARTMP
# find . | cpio --create --format='newc' | gzip > $ROOTFS_IMG
find . | cpio -o -H newc | gzip > "$ROOTFS_IMG"
cd - &> /dev/null
echo "done"

echo -n "Performing cleanup..."
rm -rf $TARTMP
echo "done"

ENDSEC=`date +"%s"`
ENDDATE=`date`

echo "ROOTFS assembling started at $STARTDATE and ended at $STARTDATE"
TIMEDIFF=`expr $ENDSEC - $STARTSEC`
MIN=`expr $TIMEDIFF / 60`
SEC=`expr $TIMEDIFF % 60`
echo "Elapsed time = $MIN minutes $SEC seconds"

echo "File system image created in $ROOTFS_IMG"

