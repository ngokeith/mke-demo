#!/bin/bash

#### Opening dklb-pool-1 workloads
echo
echo "**** Setting env var DKLB_PUBLIC_AGENT_IP"
echo
export DKLB_PUBLIC_AGENT_IP=$(dcos task exec -it dcos-edgelb.pools.dklb curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $DKLB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### GET PUBLIC IP OF GITLAB POOL
echo
echo "**** Setting env var EDGELB_PUBLIC_AGENT_IP"
echo
export EDGELB_PUBLIC_AGENT_IP=$(dcos task exec -it kubectl-two-clusters__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $EDGELB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### WAIT FOR MKE-L7.DDNS.NET HELLO-WORLD SERVICE TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s -H "Host: mke-l7.ddns.net" $DKLB_PUBLIC_AGENT_IP | grep -q "Hello"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for L4/L7 services to be exposed. Still waiting.\n"
      sleep 5
  fi
done

#### WAIT FOR MKE-L7.DDNS.NET DCOS-SITE SERVICE TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s -H "Host: mke-l7.ddns.net" $DKLB_PUBLIC_AGENT_IP:81 | grep -q "The Definitive Platform for Modern Apps"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for L4/L7 services to be exposed. Still waiting.\n"
      sleep 5
  fi
done


#### OPEN WORKLOADS
echo "Opening workloads..."
echo
echo
open -na "/Applications/Google Chrome.app"/ http://$EDGELB_PUBLIC_AGENT_IP:10006
echo
open -na "/Applications/Google Chrome.app"/ http://$DKLB_PUBLIC_AGENT_IP:10001
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:80
sleep 1
open -na "/Applications/Google Chrome.app"/ http://$DKLB_PUBLIC_AGENT_IP:10002
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:81/docs/latest/
echo
echo
echo -e "To enable Mesos Metrics, if on CoreOS run \x1B[1m./start_vpn_coreos.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics_coreos.sh\x1B[0m in a seperate tab"
echo
echo -e "To enable Mesos Metrics, if on CentOS run \x1B[1m./start_vpn_centos.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics_centos.sh\x1B[0m in a seperate tab"
echo
echo "If you want to view the Kafka dashboard in Grafana, import dashboard 9018"
echo
echo
echo
