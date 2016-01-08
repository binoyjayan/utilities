#!/bin/bash

# Please take a copy of this script and then open
# Script to create rootfs image
# Delete device files from vanilla rootfs and enable DEVTMPFS in kernel 
# tar --delete --file=rootfs.tar ./dev/console

BASESTR=`basename $0`
ROOTDIR=`readlink -m .`
ROOTFS_IMG=$ROOTDIR/system.img
TARTMP=/tmp/__tar_temp_dir__
#FSSIZE=300M
FSSIZE=50M

if [ "$#" -lt 2 ]
then
        echo ""
        echo "Usage : $BASESTR <rootfs vanilla img> <lib/modules folder> [output image name]"
        echo ""
        echo "  rootfs vanilla img     : Should be in tar.gz format"
        echo "  lib/modules            : Should contain the kernel modules"
        echo "                           This is where the make modules_install command installs kernel modules"
        echo "  output image name      : Name of the output rootfs image in ext4 format (optional)"
        echo "                           Default Value is $ROOTFS_IMG"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR rootfs_vanilla.tar.bz2 ~/kernel/ANDROID/build/rootfs/lib/modules $ROOTFS_IMG"
        echo " $BASESTR rootfs_vanilla.tar.bz2 ~/kernel/ANDROID/build/rootfs/lib/modules"
        echo ""
        exit
fi

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
#       exit
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

echo -n "Creating temporary working directory to mount file system image..."
mkdir -p $TARTMP
echo "done."

echo -n "Extracting vanilla kernel to temporary directory..."
rm -rf $TARTMP/*
cd $TARTMP
tar xf $ROOTFS_TAR
rm $TARTMP/init
cd -
#ln -s init $TARTMP/init
echo "done."

echo -n "Copying the modules to rootfs..."
rm -rf $TARTMP/lib/modules/*
cp -a $MODULES_DIR/* $TARTMP/lib/modules/
echo "done."

echo "Creating eMMC card compatible ext4 file system [$FSSIZE]..."
cd /tmp
# echo make_ext4fs -l $FSSIZE -a system $ROOTFS_IMG $TARTMP/
make_ext4fs -l $FSSIZE -a system $ROOTFS_IMG $TARTMP/
cd -
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

