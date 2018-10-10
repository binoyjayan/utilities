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
	echo "  aarch64-linux-gnu-gdb vmlinux"
	echo "  target remote localhost:1234"
	echo ""
}

DBG=""
KLOC="/local/mnt/workspace/src/korg/linux_arm64"
RLOC="/local/mnt/workspace/images/rootfs/arm64"

KERNEL="arch/arm64/boot/Image"
DISKA="rootfs.ext4"
DISKB="HDB.ext4"

K=$KLOC/$KERNEL
R=$RLOC/$DISKA
D=$RLOC/$DISKB


if [ "$1" == '-h' ]
then
	usage
	exit
elif [ "$1" == '-g' ]
then
	DBG="-s -S"
	echo "Running qemu in debug mode [$DBG]. Connect using a gdb client as:"
	echo ""
	echo "aarch64-linux-gnu-gdb vmlinux"
	echo "target remote localhost:1234"
	echo ""
fi

echo ""
echo "KERNEL : $K"
echo "ROOTFS : $R"
echo "DISK2  : $D"
echo ""


qemu-system-aarch64 \
 -machine virt \
 -machine type=virt \
 -cpu cortex-a57 \
 -nographic \
 -smp 1 -m 2048 \
 -kernel $K \
 -append "console=ttyAMA0 root=/dev/vda rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
 -drive file=$D,format=raw,id=disk1,if=none \
 -device virtio-blk-device,drive=disk1 \
 -drive file=$R,format=raw,id=disk0,if=none \
 -device virtio-blk-device,drive=disk0 \
 -boot c \
  $DBG \
 | tee serial.log

# -s -S \
# -append "console=ttyAMA0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -append "console=ttyAMA0 root=$RDEV rw rootfstype=ext4 init=/init" \
# -s shorthand for -gdb tcp::1234 - listen to gdb client at port 1234
# -S freeze CPU at startup (use 'c' to start execution)
# gdb ./vmlinux
# (gdb) target remote localhost:1234
# (gdb) continue


