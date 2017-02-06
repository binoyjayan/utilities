#!/bin/bash

DBG=""
KLOC="/local/mnt/workspace/src/korg/linux_arm64"
RLOC="/local/mnt/workspace/images/rootfs/arm64"

KERNEL="arch/arm64/boot/Image"
DISKA="rootfs.ext4"
DISKB="HDB.ext4"

K=$KLOC/$KERNEL
R=$RLOC/$DISKA
D=$RLOC/$DISKB

echo ""
echo "KERNEL : $K"
echo "ROOTFS : $R"
echo "DISK2  : $D"
echo ""

if [ "$1" == '-g' ]
then
	DBG="-s -S"
fi

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


