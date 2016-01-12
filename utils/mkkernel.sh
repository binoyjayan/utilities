#!/bin/bash

# Please take a copy of this script and then open
#Uses custom toolchain

BASESTR=`basename $0`
# DEFCONFIG=versatile_defconfig
DEFCONFIG=msm8960_adp_defconfig
THEARCH=arm
IMGNAME=zImage
# PREFIX=arm-linux-gnueabi-
# PREFIX=aarch64-linux-gnu-
PREFIX=arm-linux-gnueabihf-

if [ "$#" -lt 2 ]
then
        echo ""
        echo "Usage : $BASESTR <kernel dir> <build output dir> [defconfig_file] [arch]"
        echo ""
        echo "Default value for defconfig_file : $DEFCONFIG"
        echo "Default value for arch           : $THEARCH"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR linux-3.14 linux-3.14_build apq8064_adp2es2p5_defconfig"
        echo " $BASESTR linux-3.14 linux-3.14_build ifc6410_8064_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build versatile_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build apq8084_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build apq8084_defconfig"
        echo " $BASESTR linux-3.14 linux-3.14_build msm8960_adp_defconfig"
        echo " $BASESTR linux-3.14 linux-3.14_build mdm9640_defconfig"
        echo ""
        exit
fi

echo "done."

echo -n "Validating kernel source directory and configuration options..."
if [ ! -d "$1" ]
then
        echo "The directory '$1' was not found"
        exit
fi

if [ "$3" != "" ]
then
        DEFCONFIG=$3
fi
if [ "$4" != "" ]
then
        THEARCH=$4
fi

echo "done"

# Use Ubuntu toolchain
export CC=$PREFIX-gcc
export CROSS_COMPILE=$PREFIX

KDIR=`readlink -m $1`
BUILDDIR=`readlink -m $2`

STARTDATE=`date`
STARTSEC=`date +"%s"`

mkdir -p $BUILDDIR

cd $KDIR

echo -n "Cleanup the kernel build tree.."
# make mrproper
# rm -rf $BUILDDIR/*
echo "done."

echo "Configuring the kernel with the following options:"
echo "make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX $DEFCONFIG"
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX $DEFCONFIG

# Enable this if you want to customize the kernel using prev configuration
# make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX oldconfig

# Enable this if you want to customize the kernel using menuconfig
# make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX menuconfig
# make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX savedefconfig
# cp $BUILDDIR/defconfig arch/$THEARCH/configs/$DEFCONFIG

echo "Building kernel [$IMGNAME] .."
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX

# echo "Building modules.."
# make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX modules

echo "Building DTB.."
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX dtbs

echo "Installing rootfs at $BUILDDIR/rootfs..."
mkdir -p $BUILDDIR/rootfs
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=$PREFIX modules_install INSTALL_MOD_PATH=$BUILDDIR/rootfs

# Run the following command to install the kernel
# sudo make O=$BUILDDIR modules_install install

cd -
ENDSEC=`date +"%s"`
ENDDATE=`date`

echo "Build started at $STARTDATE and ended at $STARTDATE"
TIMEDIFF=`expr $ENDSEC - $STARTSEC`
MIN=`expr $TIMEDIFF / 60`
SEC=`expr $TIMEDIFF % 60`
echo "Elapsed time = $MIN minutes $SEC seconds"
