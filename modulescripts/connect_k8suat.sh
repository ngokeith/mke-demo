#!/bin/bash

#### GET PUBLIC IP OF EDGE-LB PUBLIC AGENT
echo
echo "**** Setting env var UAT_K8S_EDGELB"
echo
export KUBECTL_POOL_PUBLIC_IP=$(dcos task exec -it kubectl-pool__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $KUBECTL_POOL_PUBLIC_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### SETUP KUBECTL FOR /uat/kubernetes-uat

echo
echo "**** Running dcos kubernetes cluster kubeconfig for /uat/kubernetes-uat, as context 'uat'"
echo
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=uat --cluster-name=uat/kubernetes-uat --apiserver-url=https://$KUBECTL_POOL_PUBLIC_IP:6445

#### TEST KUBECTL WITH /uat/kubernetes-uat

echo
echo "**** Running kubectl get nodes for /uat/kubernetes-uat"
echo
kubectl get nodes
