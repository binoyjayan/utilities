#!/bin/bash

if [ "$1" == "" ]; then
    echo "Expected instance id"
    exit
fi

for id in "$@"; do
    echo "Terminating instance $id"
    aws ec2 terminate-instances --instance-ids $id
done

