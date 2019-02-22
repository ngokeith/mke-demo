#!/bin/bash

#### GET PUBLIC IP OF PROD-LB-POOL
echo
echo "**** Setting env var PROD_POOL_PUBLIC_IP"
echo
export PROD_POOL_PUBLIC_IP=$(dcos task exec -it dcos-edgelb.pools.prod-lb-pool curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $PROD_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### GET PUBLIC IP OF DEV-LB-POOL
echo
echo "**** Setting env var DEV_POOL_PUBLIC_IP"
echo
export DEV_POOL_PUBLIC_IP=$(dcos task exec -it dcos-edgelb.pools.dev-lb-pool curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $DEV_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### GET PUBLIC IP OF GITLAB POOL
echo
echo "**** Setting env var GITLAB_PUBLIC_IP"
echo
export GITLAB_PUBLIC_IP=$(dcos task exec -it kubectl-two-clusters__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $GITLAB_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip


#### WAIT FOR MKE-L7.DDNS.NET HELLO-WORLD SERVICE TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s -H "Host: mke-l7.ddns.net" $PROD_POOL_PUBLIC_IP | grep -q "Hello"; then
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
  if curl -s http://$DEV_POOL_PUBLIC_IP:10001 | grep -q "Hello"; then
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
open -na "/Applications/Google Chrome.app"/ http://$GITLAB_PUBLIC_IP:10006
echo
open -na "/Applications/Google Chrome.app"/ http://dcos-jupyterlabdemo.ddns.net:10005/datascience/jupyterlab-notebook
echo
open -na "/Applications/Google Chrome.app"/ http://$DEV_POOL_PUBLIC_IP:10001
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:80
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:81
sleep 1
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
