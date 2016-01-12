#!/bin/bash

# Please take a copy of this script and then open
# Uses Ubuntu toolchain

BASESTR=`basename $0`
# DEFCONFIG=versatile_defconfig
DEFCONFIG=apq8084_defconfig
THEARCH=arm
PREFIX=arm-linux-gnueabi-

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
        echo " $BASESTR linux-3.14 linux-3.14_build ifc6410_8064_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build versatile_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build apq8084_defconfig arm"
        echo " $BASESTR linux-3.14 linux-3.14_build apq8084_defconfig"
        echo " $BASESTR linux-3.14 linux-3.14_build msm8960_adp_defconfig"
        echo " $BASESTR linux-3.14 linux-3.14_build full_msm8960-perf_defconfig"
        echo ""
        exit
fi

echo -n "Check if toolchain is installed..."
dpkg -s gcc-arm-linux-gnueabi &> /dev/null
TOOL1=$?
dpkg -s binutils-arm-linux-gnueabi  &> /dev/null
TOOL2=$?

if [ "$TOOL1" != "0" -o "$TOOL2" != "0" ]
then
        echo ""
        echo "One or more tool chain are missing."
        echo "Please use the following command to install toolchain:"
        echo "sudo apt-get install gcc-arm-linux-gnueabi"
        echo "sudo apt-get install binutils-arm-linux-gnueabi"
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
export CC=arm-linux-gnueabi-gcc
export CROSS_COMPILE=arm-linux-gnueabi-

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
echo "make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=arm-linux-gnueabi- $DEFCONFIG"
#make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=arm-linux-gnueabi- $DEFCONFIG

# Enable this if you want to customize the kernel
make O=$BUILDDIR ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- menuconfig


exit
echo "Building kernel.."
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=arm-linux-gnueabi-

echo "Building DTB.."
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=arm-linux-gnueabi- zImage-dtb
cat $BUILDDIR/arch/arm/boot/zImage $BUILDDIR/arch/arm/boot/dts/apq8084-v1.1-sbc.dtb > $BUILDDIR/arch/arm/boot/zImage-dtb

echo "Installing rootfs at $BUILDDIR/rootfs..."
mkdir -p $BUILDDIR/rootfs
make O=$BUILDDIR ARCH=$THEARCH CROSS_COMPILE=arm-linux-gnueabi- modules_install INSTALL_MOD_PATH=$BUILDDIR/rootfs

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
