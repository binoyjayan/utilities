#!/usr/bin/env bash
set -e
set -o pipefail

export AWS_PAGER=

base=$(basename $0)
created_by=$(id -un)
vol_del_on_term=True
instance_type="t3.small"
subnet_id="subnet-2595e242"
image_id="ami-0022f774911c1d690"  # Amazon Linux AMI
security_group_id="sg-03b8ebb770a5676cf" # nsg-a
user_data_file="instance-user-data-file.sh"

# Create a user-data file
cat > "${user_data_file}" <<EOF_TEST_USER_DATA
#!/bin/bash

sleep 10

# Install default packages
yum -y install iperf3 jq htop

# Optional packages
# yum install docker && usermod -aG docker ec2-user && systemctl start docker

# Package installations that can fail
yum -y install perf

EOF_TEST_USER_DATA


usage() {
    echo ""
    echo "Usage:"
    echo "$1 <ssh-key-name> <instance-name> [subnet-id] [security-group-id]"
    echo ""
    echo "Examples:"
    echo "$1 bjayan-ctapdev-aws bjayan-test1 $subnet_id $security_group_id"
    echo ""
}

ssh_key="$1"
instance_name="$2"
if [ "$ssh_key" == "" ]; then
    usage $base
    exit 1
fi

if [ "$instance_name" == "" ]; then
    usage $base
    exit 1
fi

if [ "$3" != "" ]; then
    subnet_id="$3"
    echo "Using subnet $subnet_id"
fi

if [ "$4" != "" ]; then
    security_group_id="$4"
    echo "Using security group $security_group_id"
fi

tags_list='Tags=[{Key=Name,Value='$instance_name'},{Key=cpacket:CreatedBy,Value='$created_by'}]'
tags_spec="ResourceType=instance,$tags_list"

echo "Creating instance..."

aws ec2 run-instances \
    --image-id "$image_id" \
    --count 1 \
    --instance-type "$instance_type" \
    --key-name "$ssh_key" \
    --security-group-ids "$security_group_id" \
    --subnet-id "$subnet_id" \
    --tag-specifications "$tags_spec" \
    --user-data "file://${user_data_file}"

