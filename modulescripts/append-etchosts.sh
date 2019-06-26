#!/bin/bash

MASTER_IP=$(dcos node | grep "master" | tail -1 | awk '{print $2}')

#### GET PUBLIC IP OF KUBECTL POOL
echo
echo "**** Setting env var KUBECTL_POOL_PUBLIC_IP"
echo
# export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool-0 curl ifconfig.co | tr -d '\r' | tr -d '\n')
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

#### SETUP HOSTS FILE FOR mke-l7.ddns.net

echo
echo "**** Copying /etc/hosts to /tmp/hosts as a backup, deleting /tmp/hosts if it exists"
echo
rm -f /tmp/hosts 2> /dev/null
cp /etc/hosts /tmp

if [ -n "$(grep mke-l7.ddns.net /etc/hosts)" ]; then
    echo "**** mke-l7.ddns.net line found in /etc/hosts, removing that line";
    echo
    sed -i '' '/mke-l7.ddns.net/d' /etc/hosts
else
    echo "**** mke-l7.ddns.net was not found in /etc/hosts";
    echo
fi

if [ -n "$(grep dcos-gitlabdemo.ddns.net /etc/hosts)" ]; then
    echo "**** dcos-gitlabdemo.ddns.net line found in /etc/hosts, removing that line";
    echo
    sed -i '' '/dcos-gitlabdemo.ddns.net/d' /etc/hosts
else
    echo "**** dcos-gitlabdemo.ddns.net was not found in /etc/hosts";
    echo
fi

echo "**** Adding entries to /etc/hosts for mke-l7.ddns.net for $KUBECTL_POOL_PUBLIC_IP"
echo "$KUBECTL_POOL_PUBLIC_IP mke-l7.ddns.net" >> /etc/hosts
echo "$SERVICES_POOL_PUBLIC_IP dcos-gitlabdemo.ddns.net" >> /etc/hosts
#echo "$GITLAB_POOL_PUBLIC_IP dcos-jupyterlabdemo.ddns.net" >> /etc/hosts
# to bypass DNS & hosts file: curl -H "Host: www.apache.test" $EDGELB_PUBLIC_AGENT_IP
