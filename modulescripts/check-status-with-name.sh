#!/bin/bash

seconds=0
OUTPUT=0
sleep 5
while [ "$OUTPUT" -ne 1 ]; do
  OUTPUT=`dcos $1 --name $2 plan status deploy | head -1 | grep -c COMPLETE`;
  seconds=$((seconds+5))
  printf "Waiting %s seconds for $1 to come up.\n" "$seconds. This usually takes $3 seconds or more depending on cluster sizing"
  sleep 5
done

dcos $1 --name $2 plan status deploy
