#!/bin/bash

KLOC="/local/mnt/workspace/src/korg/linux_QEmu"
#RLOC="/local/mnt/workspace/software/linux/buildroot/buildroot-2016.05/output/images"
RLOC="/local/mnt/workspace/images/rootfs/x86_64"

#KERNEL="arch/x86/boot/bzImage"
KERNEL="arch/x86/boot/bzImage"
#DISK="hdd.img"
DISK="rootfs.ext2"
RDEV="/dev/hda"

echo "KERNEL : $KLOC/$KERNEL"
echo "ROOTFS : $RLOC/$DISK"

qemu-system-x86_64 \
 -kernel $KLOC/$KERNEL \
 -hda    $RLOC/$DISK \
 -boot c \
 -m 256 \
 -append "root=$RDEV rw console=ttyS0 root=/dev/sda" \
 -localtime \
 -no-reboot \
 -name rtlinux \
 -net nic -net user \
 -redir tcp:2222::22 \
 -redir tcp:3333::3333 \
 -smp cores=2 \
 -serial stdio \
 | tee serial.log

# -serial stdio \
# -nographic \
# -m <ramsize>
# -hda $RLOC/$DISK \

# find . | cpio -o -H newc | gzip > ../rootfs.img
# find . | cpio --create --format=newc > ../rootfs.img
