#!/bin/bash

MASTER_IP=$(dcos node | grep "master" | tail -1 | awk '{print $2}')

#### GET PUBLIC IP OF PROD-LB-POOL
echo
echo "**** Setting env var KUBECTL_POOL_PUBLIC_IP"
echo
# export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool-0 ip route get to "$MASTER_IP" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
echo Public IP of DKLB Edge-LB node is: $KUBECTL_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### GET PUBLIC IP OF SERVICES POOL
echo
echo "**** Setting env var SERVICES_POOL_PUBLIC_IP"
echo
# export SERVICES_POOL_PUBLIC_IP=$(dcos task exec -it services-pool__edgelb-pool-0 curl ifconfig.co | tr -d '\r' | tr -d '\n')
export SERVICES_POOL_PUBLIC_IP=$(dcos task exec -it services-pool__edgelb-pool-0 ip route get to "$MASTER_IP" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
echo Public IP of Edge-LB node is: $SERVICES_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip


#### WAIT FOR MKE-L7.DDNS.NET HELLO-WORLD SERVICE TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s -H "Host: mke-l7.ddns.net" $KUBECTL_POOL_PUBLIC_IP | grep -q "Hello"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for L4/L7 services to be exposed. Still waiting.\n"
      sleep 5
  fi
done

#### WAIT FOR DEV HELLO-WORLD SERVICE TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s http://$KUBECTL_POOL_PUBLIC_IP:10001 | grep -q "Hello"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for L4/L7 services to be exposed. Still waiting. (Make sure ports 10001-10006 are open \n"
      sleep 5
  fi
done

#### OPEN WORKLOADS
echo "Opening workloads..."
echo
echo
#launch Chrome with Grafana Dashboard
echo "Accessing Grafana Dashboard in a new browser tab."
open -na "/Applications/Google Chrome.app"/ `dcos config show core.dcos_url`/service/dcos-monitoring/grafana/
echo
open -na "/Applications/Google Chrome.app"/ http://$SERVICES_POOL_PUBLIC_IP:10006
echo
open -na "/Applications/Google Chrome.app"/ http://$SERVICES_POOL_PUBLIC_IP:10005/datascience/jupyterlab-notebook
echo
open -na "/Applications/Google Chrome.app"/ http://$KUBECTL_POOL_PUBLIC_IP:10001
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:80
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:81
sleep 1
echo
echo
echo -e "To enable Mesos Metrics, run \x1B[1m./start_vpn.sh <OS USER> \x1B[0m before executing \x1B[1m./enable_mesos_metrics.sh <OS USER>\x1B[0m in a seperate tab"
echo
echo -e "Additionally, to enable EdgeLB Metrics, run \x1B[1m./enable_edgelb_metrics.sh <OS USER>\x1B[0m as well"
echo
echo "If you want to view the Kafka dashboard in Grafana, import dashboard 9018 and 9947"
echo
echo
echo
