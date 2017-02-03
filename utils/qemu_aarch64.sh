#!/bin/bash

KLOC="/local/mnt/workspace/src/korg/linux_arm64"
RLOC="/local/mnt/workspace/images/rootfs/arm64"

KERNEL="arch/arm64/boot/Image"
DISKA="rootfs.ext4"
DISKB="HDB.ext4"
RDEV="/dev/vda"

K=$KLOC/$KERNEL
R=$RLOC/$DISKA
D=$RLOC/$DISKB

# v0: No dm-crypt changes; only dbg msgs
# v1: geniv changes; smaller blocks
# v2: geniv changes; larger  blocks

#K=/local/mnt/workspace/images/dm/bzImages/bzImage.v0_2

echo ""
echo "KERNEL : $K"
echo "ROOTFS : $R"
echo "DISK2  : $D"
echo ""

qemu-system-aarch64 \
 -kernel $K \
 -drive file=$R,format=raw \
 -drive file=$D,format=raw \
 -append "console=ttyAMA0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
 -machine virt \
 -cpu cortex-a57 \
 -machine type=virt \
 -nographic \
 -smp 1 \
 -m 1024 \
 | tee serial.log

# -s -S \
# -cpu cortex-a57 \
# -drive format=raw \
# -kernel aarch64-linux-3.15rc2-buildroot.img 
# --append "console=ttyAMA0"
# -boot c \
# -append "console=ttyAMA0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -append "console=ttyAMA0 root=$RDEV rw rootfstype=ext4 init=/init" \

# -s shorthand for -gdb tcp::1234 - listen to gdb client at port 1234
# -S freeze CPU at startup (use 'c' to start execution)
# gdb ./vmlinux
# (gdb) target remote localhost:1234
# (gdb) continue


