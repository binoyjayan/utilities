#!/bin/bash

if [ "$1" == "" ]; then
    echo "Expected instance id"
    exit
fi

for id in "$@"; do
    echo "Starting instance $id"
    aws ec2 start-instances --instance-ids $id
done

