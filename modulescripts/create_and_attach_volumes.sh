#!/bin/bash

eval $(maws login 110465657741_Mesosphere-PowerUser)

#name=$1
#region=$2

aws --region=$2 ec2 describe-instances |  jq --raw-output ".Reservations[].Instances[] | select((.Tags | length) > 0) | select(.Tags[].Value | test(\"$1-privateagent\")) | select(.State.Name | test(\"running\")) | [.InstanceId, .Placement.AvailabilityZone] | \"\(.[0]) \(.[1])\"" | while read instance zone; do
  volume=$(aws --region=$2 ec2 create-volume --size=100  --availability-zone=$zone --tag-specifications="ResourceType=volume,Tags=[{Key=string,Value=$1}]" | jq --raw-output .VolumeId)
  sleep 10
  aws --region=$2 ec2 attach-volume --device=/dev/xvdf --instance-id=$instance --volume-id=$volume
done
