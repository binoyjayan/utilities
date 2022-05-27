#!/usr/bin/env bash
set -e
set -o pipefail

ssh_key="$1"
instance_name="$2"
if [ "$ssh_key" == "" ]; then
    echo "Specify an ssh key name"
    exit
fi

if [ "$instance_name" == "" ]; then
    echo "Specify an instance name"
fi


vol_del_on_term=True
created_by=$(id -un)
image_id="ami-0022f774911c1d690"  # Amazon Linux AMI
instance_type="m5n.2xlarge"
subnet_id="subnet-2595e242"
security_group_id="sg-03b8ebb770a5676cf" # nsg-a
tags_list='Tags=[{Key=Name,Value='$instance_name'},{Key=CreatedBy,Value='$created_by'}]'
tags_spec="ResourceType=instance,$tags_list"

get_data_disk_cfg() {
    local vol_size=$1
    local vol_num=$2
    local count=0
    local drive_letters=("d" "e" "f" "g" "h" "i")
    local disk_cfg=""
    if ((vol_num > 5)); then
        vol_num=5
    fi
    for (( i=1; i<=vol_num; i++ )); do
        cfg="DeviceName=/dev/sd${drive_letters[$i]},Ebs={DeleteOnTermination=${vol_del_on_term},VolumeSize=${vol_size},VolumeType=gp2}"
        disk_cfg="${disk_cfg} $cfg"
        count=$((count + 1))
    done
    echo $disk_cfg
}

export AWS_PAGER=

data_disk_cfg=$(get_data_disk_cfg 32 1)
aws ec2 run-instances \
    --image-id "$image_id" \
    --count 1 \
    --instance-type "$instance_type" \
    --key-name "$ssh_key" \
    --security-group-ids "$security_group_id" \
    --subnet-id "$subnet_id" \
    --block-device-mappings $data_disk_cfg \
    --tag-specifications "$tags_spec"

