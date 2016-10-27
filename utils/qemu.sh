#!/bin/bash

KLOC="/local/mnt/workspace/src/korg/linux_x86"
#RLOC="/local/mnt/workspace/software/linux/buildroot/buildroot-2016.05/output/images"
RLOC="/local/mnt/workspace/images/rootfs/x86_64"

#KERNEL="arch/x86/boot/bzImage"
KERNEL="arch/x86/boot/bzImage"
# DISK="rootfs.ext2"
DISKA="rootfs.ext4"
DISKB="HDB.ext4"
RDEV="/dev/sda"

echo "KERNEL : $KLOC/$KERNEL"
echo "ROOTFS : $RLOC/$DISKA"
echo "DISK2  : $RLOC/$DISKB"

qemu-system-x86_64 \
 -kernel $KLOC/$KERNEL \
 -hda    $RLOC/$DISKA \
 -hdb    $RLOC/$DISKB \
 -boot c \
 -m 256 \
 -append "console=ttyS0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
 -localtime \
 -no-reboot \
 -name rtlinux \
 -netdev user,id=network0 -device e1000,netdev=network0 \
 -smp cores=2 \
 -nographic \
 | tee serial.log

# -append "console=ttyS0 root=/dev/nfs nfsroot=10.0.2.2:/srv/nfs rw ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -append "console=ttyS0 root=$RDEV rw rootfstype=ext4" \
# -append "console=ttyS0 root=$RDEV rw rootfstype=ext4 ip=10.0.2.15::10.0.2.1:255.255.255.0 init=/init" \
# -serial stdio \
# NFS mount
# mount 10.0.2.2:/srv/nfs /mnt
