#!/bin/bash

if [ "$1" == "" ]; then
    echo "Specify file name as argument"
    exit
fi

file_name="$1"

echo
echo "File name: $file_name"
echo

fio --name=read_write_test \
    --filename="$file_name" \
    --rw=readwrite \
    --bs=128k \
    --numjobs=1 \
    --iodepth=4 \
    --time_based \
    --fill_device=1

