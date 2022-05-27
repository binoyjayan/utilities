#!/bin/bash

if [ "$1" == "" ]; then
    echo "Expected instance id"
    exit
fi

for id in "$@"; do
    echo "Stopping instance $id"
    aws ec2 stop-instances --instance-ids $id
done

