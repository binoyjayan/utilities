#!/usr/bin/env python3

import os
import subprocess


def get_block_device_from_df():
    try:
        root_device = subprocess.check_output(
            ["df", "--output=source", "/"], universal_newlines=True
        ).splitlines()[1]
    except subprocess.CalledProcessError:
        return None

    return root_device


def find_block_device_from_label(label):
    label_path = f"/dev/disk/by-label/{label}"
    try:
        device_path = os.path.realpath(label_path)
        return device_path
    except FileNotFoundError:
        return None


def find_parent_disk_from_partition(blockdev):
    try:
        root_device = subprocess.check_output(
            ["lsblk", "-no", "pkname", blockdev], universal_newlines=True
        )
        return "/dev/" + root_device.rstrip()
    except subprocess.CalledProcessError:
        return None


def get_block_device_from_mount(mounts_file, mount_point):
    try:
        with open(mounts_file, "r") as f:
            for line in f:
                fields = line.strip().split()
                if len(fields) >= 2 and fields[1] == mount_point:
                    return fields[0]
    except FileNotFoundError:
        pass
    return None


# Validate that a block device has a file system with the given label
def block_device_validate_fs(blockdev, label):
    command = f"blkid {blockdev}"
    result = subprocess.run(
        command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    if result.returncode == 0:
        output_lines = result.stdout.split("\n")
        for line in output_lines:
            if f'LABEL="{label}"' in line and 'TYPE="ext4"' in line:
                return True
        return False
    else:
        return False


root_device = get_block_device_from_df()
print(f"Root Device for df: {root_device}")

root_device = get_block_device_from_mount("/proc/mounts", "/")
print(f"Root Device for mount point file: {root_device}")

part_root = find_parent_disk_from_partition(root_device)
print(f"The parent device for a partition {part_root}")

device = find_block_device_from_label("sys1")
print(f"The device is with label: {device}")
