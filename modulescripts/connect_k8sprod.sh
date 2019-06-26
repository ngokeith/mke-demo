#!/bin/bash

MASTER_IP=$(dcos node | grep "master" | tail -1 | awk '{print $2}')

#### GET PUBLIC IP OF EDGE-LB PUBLIC AGENT
echo
echo "**** Setting env var PROD_K8S_EDGELB"
echo
# export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool-0 curl ifconfig.co | tr -d '\r' | tr -d '\n')
export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool-0 ip route get to "$MASTER_IP" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
echo Public IP of Edge-LB node is: $KUBECTL_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### SETUP KUBECTL FOR /PROD/KUBERNETES-PROD

echo
echo "**** Running dcos kubernetes cluster kubeconfig for /prod/kubernetes-prod, as context 'prod'"
echo
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=prod --cluster-name=prod/kubernetes-prod --apiserver-url=https://$KUBECTL_POOL_PUBLIC_IP:6443

#### TEST KUBECTL WITH /PROD/KUBERNETES-PROD

echo
echo "**** Running kubectl get nodes for /prod/kubernetes-prod"
echo
kubectl get nodes
