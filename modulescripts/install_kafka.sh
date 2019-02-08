#!/bin/bash

echo
echo "**** Installing kafka v$1"
echo
dcos package install kafka --package-version=$1 --options=options-kafka.json --yes
sleep 20
seconds=20
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the public kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kafka plan status deploy --name=kafka | grep kafka-2 | awk '{print $3}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kafka to start. Still waiting. This normally takes around 60-90 seconds\n"
  sleep 10
done
