#!/bin/bash

Q_AZ="Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}"
Q_STATE="Reservations[*].Instances[*].{Instance:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}"
# Q_STATE="Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}"

F_NAME="Name=tag:CreatedBy,Values=$USER"

aws ec2 describe-instances \
  --filters Name=tag-key,Values=Name \
  --query  $Q_STATE \
  --filters $F_NAME \
  --output table
