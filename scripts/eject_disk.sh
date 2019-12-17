#!/bin/bash

DISK=$1
WHOAMI=`whoami`

if [ "$WHOAMI" != "root" ]
then
    echo "Run as root"
    exit
fi

if [ "$DISK" == "" ]
then
    echo "Specify the block device to eject"
    exit
fi

if [ ! -b "$DISK" ]
then
    echo "\"$DISK\" is not a block device"
    exit
fi

# echo "Unmounting file systems on $DISK..."
# udisksctl unmount -b /dev/sdb1

echo "Ejecting disk $DISK..."
udisksctl power-off -b /dev/sdb

# udisks --unmount /dev/sda1
# udisks --detach /dev/sda
