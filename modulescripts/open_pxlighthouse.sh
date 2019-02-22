#!/bin/bash

#### GET PUBLIC IP OF PX-LIGHTHOUSE
echo
echo "**** Setting env var PXLIGHTHOUSE_PUBLIC_IP"
echo
export PXLIGHTHOUSE_PUBLIC_IP=$(dcos task exec -it lighthouse curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $PXLIGHTHOUSE_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### WAIT FOR INFRA PX-LIGHTHOUSE SERVICE TO BE AVAILABLE
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s http://$PXLIGHTHOUSE_PUBLIC_IP:8085 | grep "login"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for PX-Lighthouse to be available. Still waiting. (Make sure ports 8085 is open \n"
      sleep 5
  fi
done

open -na "/Applications/Google Chrome.app"/ http://$PXLIGHTHOUSE_PUBLIC_IP:8085
