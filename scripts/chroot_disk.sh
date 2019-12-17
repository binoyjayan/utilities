#!/bin/bash

BLOCK=2048
BS=512
OFFSET=`expr $BLOCK \* $BS`
echo "Mounting file system at offset $OFFSET [ block:$BLOCK bs:$BS ]"

mkdir -p /mnt/disk
mount -o loop,offset=$OFFSET disk.img /mnt/disk

echo sudo mount -t proc proc /mnt/disk/proc
echo sudo mount -t sysfs sys /mnt/disk/sys
echo sudo mount -o bind /dev /mnt/disk/dev

echo sudo mv /mnt/disk/etc/resolv.conf /mnt/disk/etc/resolv.conf.bkp
echo sudo cp -L /etc/resolv.conf /mnt/disk/etc/resolv.conf
echo sudo chroot /mnt/disk /bin/bash


echo "cleanup..."
echo sudo rm /mnt/disk/etc/resolv.conf
echo sudo mv /mnt/disk/etc/resolv.conf.bkp /mnt/disk/etc/resolv.conf

echo sudo umount /mnt/disk/dev
echo sudo umount /mnt/disk/sys
echo sudo umount /mnt/disk/proc
echo sudo umount /mnt/disk

