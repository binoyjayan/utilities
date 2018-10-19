#!/bin/bash
BASESTR=`basename $0`
if [ "$#" -lt 1 ]
then
        echo ""
        echo "Usage : $BASESTR <kernel build dir> [OUTDIR NAME]"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR linux-3.14_build"
        echo " $BASESTR build_4.4"
        echo " $BASESTR build_4.4 bootimages"
        echo ""
        exit
fi

if [ ! -d "$1" ]
then
        echo "The directory '$1' was not found"
        exit
fi
BUILDDIR="$1"

OUTDIR=/local/mnt/workspace/images/8996
if [ -z "$2" ]
then
	OUTIMAGE=$OUTDIR/boot.img
	DTIMG=$OUTDIR/dt.img
else
	OUTNAME=`basename $2`
	mkdir -p $OUTDIR/$OUTNAME
	OUTIMAGE=$OUTDIR/$OUTNAME/boot.img
	DTIMG=$OUTDIR/$OUTNAME/dt.img
fi

RAMFS=/local/mnt/workspace/images/rootfs/kdev/initrd-arm-msm8916.gz
# RAMFS=/local/mnt/workspace/images/rootfs/kdev/initrd_file.gz
KERNELIMG=$BUILDDIR/arch/arm64/boot/Image
DTB=$BUILDDIR/arch/arm64/boot/dts/qcom/
dtcpath=$BUILDDIR/scripts/dtc/
# CMDLINE="root=/dev/disk/by-partlabel/rootfs rw rootwait console=tty0 console=ttyMSM0,115200n8 text androidboot.emmc=true androidboot.serialno=1f9800d3 androidboot.baseband=apq systemd.unit=multi-user.target"
# CMDLINE="root=/dev/ram0 rw rootwait console=ttyMSM0,115200n8"
CMDLINE="root=/dev/ram0 rw rootwait console=ttyMSM0,115200n8 pd_ignore_unused=1"
BASEADDR=0x80000000
PAGESIZE=2048
MKBOOTIMG=mkbootimg
DTBTOOL=dtbtool
 
rm -f $DTIMG $OUTIMAGE
 
$DTBTOOL -o $DTIMG -s 2048 $DTB
 
echo ""
echo "Image     : $KERNELIMG"
echo "Initramfs : $RAMFS"
echo "Base      : $BASEADDR"
echo "Cmdline   : $CMDLINE"
echo "Output    : $OUTIMAGE"
 
$MKBOOTIMG \
    --kernel $KERNELIMG \
    --ramdisk $RAMFS \
    --cmdline "$CMDLINE" \
    --base $BASEADDR \
    --pagesize $PAGESIZE \
    --dt $DTIMG \
    --output $OUTIMAGE

chmod a+x $OUTIMAGE

echo ""
echo "Use the following command to boot/flash it on board"
echo ""
echo "sudo fastboot boot $OUTIMAGE"
echo "sudo fastboot flash $OUTIMAGE"
echo ""

