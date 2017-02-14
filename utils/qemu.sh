#!/bin/bash

BASESTR=`basename $0`
usage()
{
	echo ""
	echo "Usage:"
	echo ""
	echo "$BASESTR -h : Display this help message"
	echo "$BASESTR -g : Run qemu in debug mode by listening on tcp port 1234"
	echo ""
	echo "While running in debug mode, connect using a gdb client as:"
	echo "  gdb vmlinux"
	echo "  target remote localhost:1234"
	echo ""
}

KLOC="/local/mnt/workspace/src/korg/linux_x86"
RLOC="/local/mnt/workspace/images/rootfs/x86_64"

KERNEL="arch/x86/boot/bzImage"
DISKA="rootfs.ext4"
DISKB="HDB.ext4"
RDEV="/dev/sda"

K=$KLOC/$KERNEL
R=$RLOC/$DISKA
D=$RLOC/$DISKB

# v0: No dm-crypt changes; only dbg msgs
# v1: geniv changes; smaller blocks
# v2: geniv changes; larger  blocks

#K=/local/mnt/workspace/images/dm/bzImages/bzImage.v0
#K=/local/mnt/workspace/images/dm/bzImages/bzImage.v5

if [ "$1" == '-h' ]
then
	usage
	exit
elif [ "$1" == '-g' ]
then
	DBG="-s -S"
	echo "Running qemu in debug mode [$DBG]. Connect using a gdb client as:"
	echo ""
	echo "gdb vmlinux"
	echo "target remote localhost:1234"
	echo ""
fi

echo ""
echo "KERNEL : $K"
echo "ROOTFS : $R"
echo "DISK2  : $D"
echo ""

rm serial.log
qemu-system-x86_64 \
 -kernel $K \
 -hda    $R \
 -hdb    $D \
 -boot c \
 -m 256 \
 -append "console=ttyS0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
 -localtime \
 -no-reboot \
 -name rtlinux \
 -netdev user,id=network0 -device e1000,netdev=network0 \
 -smp cores=2 \
 -nographic \
  $DBG \
 | tee serial.log

# -s -S \
# -append "console=ttyS0 root=/dev/nfs nfsroot=10.0.2.2:/srv/nfs rw ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -append "console=ttyS0 root=$RDEV rw rootfstype=ext4" \
# -append "console=ttyS0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -serial stdio \
# NFS mount
# mount 10.0.2.2:/srv/nfs /mnt
