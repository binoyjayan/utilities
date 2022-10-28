#!/bin/bash

usage() {
    echo ""
    echo "Usage:"
    echo "$1 <ni-name> <subnet-id> <security-group-id>"
    echo ""
    echo "Examples:"
    echo "$1 bjayan-test-nic1 subnet-2595e242 sg-03b8ebb770a5676cf"
    echo ""
}

base=$(basename $0)
created_by=$(id -un)

nic_name="$1"
subnet_id="$2"
security_group_id="$3"

if [ "$nic_name" == "" ]; then
    usage $base
    exit 1
fi

if [ "$subnet_id" == "" ]; then
    usage $base
    exit 1
fi

if [ "$security_group_id" == "" ]; then
    usage $base
    exit 1
fi

tags_list='Tags=[{Key=Name,Value='$nic_name'},{Key=CreatedBy,Value='$created_by'}]'
tags_spec="ResourceType=network-interface,$tags_list"

nic_id=$(aws ec2 create-network-interface \
    --subnet-id "$subnet_id" \
    --groups "$security_group_id" \
    --description "$nic_name" \
    --tag-specifications "$tags_spec" \
    --query 'NetworkInterface.NetworkInterfaceId' \
    --output text)

echo "Created NIC: $nic_id"


