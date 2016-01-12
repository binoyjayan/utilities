#!/bin/bash

# Please take a copy of this script and then open
# Script to create rootfs image

BASESTR=`basename $0`
ROOTDIR=`readlink -m .`
ROOTFS_IMG=$ROOTDIR/rootfs.img
TARTMP=/tmp/__tar_temp_dir__
#BLKCOUNT=76800
BLKCOUNT=38400

if [ "$#" -lt 2 ]
then
        echo ""
        echo "Usage : $BASESTR <rootfs vanilla img> <lib/modules folder> [output image name]"
        echo ""
        echo "  rootfs vanilla img     : Should be in tar.gz format"
        echo "  lib/modules            : Should contain the kernel modules"
        echo "                           This is where the make modules_install command installs kernel modules"
        echo "  output image name      : Name of the output rootfs image in ext4 format (optional)"
        echo "                           Default Value is rootfs.img"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR rootfs_vanilla.tar.bz2 build_dir/rootfs/lib/modules rootfs.img"
        echo " $BASESTR rootfs_vanilla.tar.bz2 build_dir/rootfs/lib/modules"
        echo ""
        exit
fi

echo "Enter password for authentication"
sudo echo "hello" > /dev/null

echo -n "Validating rootfs and lib modules directories..."
if [ ! -f "$1" ]
then
        echo "The rootfs image file '$1' was not found"
        exit
fi

if [ ! -d "$2" ]
then
        echo "The directory '$2' was not found"
        exit
fi

if [ `basename $2` != "modules" ]
then
        echo "The directory '$2' is not a valid lib/modules directory"
        exit
fi
echo "done"

if [ "$3" != "" ]
then
        ROOTFS_IMG=`readlink -m $3`
fi

echo "Using rootfs output image - $ROOTFS_IMG"

ROOTFS_TAR=`readlink -m $1`
MODULES_DIR=`readlink -m $2`

STARTDATE=`date`
STARTSEC=`date +"%s"`

echo "Creating binary file $ROOTFS_IMG of 300 MiB..."
rm -f $ROOTFS_IMG
dd if=/dev/zero of=$ROOTFS_IMG bs=4096 count=$BLKCOUNT > /dev/null
echo "done."

echo "Creating ext4 file system image in the file $ROOTFS_IMG..."
echo y | mkfs.ext4 $ROOTFS_IMG -L SYSTEM > /dev/null
echo "done."

echo -n "Creating temporary working directory to mount file system image..."
mkdir -p $TARTMP
echo "done."

echo -n "Mounting the file system image $ROOTFS_IMG..."
sudo mount $ROOTFS_IMG $TARTMP
echo "done."

echo -n "Extracting vanilla kernel to temporary directory..."
rm -rf $TARTMP/*
tar xf $ROOTFS_TAR -C $TARTMP
cd $TARTMP
ln $TARTMP/sbin/init ./
cd -
echo "done."

echo -n "Copying the modules to rootfs..."
rm -rf $TARTMP/lib/modules/*
cp -a $MODULES_DIR/* $TARTMP/lib/modules/
echo "done."

echo -n "Performing cleanup..."
sudo umount $TARTMP
echo "done"

ENDSEC=`date +"%s"`
ENDDATE=`date`

echo "ROOTFS assembling started at $STARTDATE and ended at $STARTDATE"
TIMEDIFF=`expr $ENDSEC - $STARTSEC`
MIN=`expr $TIMEDIFF / 60`
SEC=`expr $TIMEDIFF % 60`
echo "Elapsed time = $MIN minutes $SEC seconds"

echo "File system image created in $ROOTFS_IMG"
