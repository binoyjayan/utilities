#!/bin/bash

q_ins="Reservations[*].Instances[*]"
q_iid="Instance:InstanceId"
q_az="AZ:Placement.AvailabilityZone"
q_name="Name:Tags[?Key=='Name']|[0].Value}"
q_state="Type:InstanceType,State:State.Name"
q_net="PrivateIp:PrivateIpAddress,PubicIp:NetworkInterfaces[0].Association.PublicIp"
q_all="${q_ins}.{${q_iid},${q_net},${q_state},${q_name}"

f_name="Name=tag:cpacket:CreatedBy,Values=$USER"

aws ec2 describe-instances \
  --query  $q_all \
  --filters $f_name \
  --output table
