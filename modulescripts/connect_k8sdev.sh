#!/bin/bash

#### GET PUBLIC IP OF EDGE-LB PUBLIC AGENT
echo
echo "**** Setting env var DEV_K8S_EDGELB"
echo
export DEV_K8S_EDGELB=$(dcos task exec -it kubectl-two-clusters__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $DEV_K8S_EDGELB
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### SETUP KUBECTL FOR /PROD/KUBERNETES-PROD

echo
echo "**** Running dcos kubernetes cluster kubeconfig for /prod/kubernetes-prod, as context 'prod'"
echo
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=dev --cluster-name=dev/kubernetes-dev --apiserver-url=https://$DEV_K8S_EDGELB:6444

#### TEST KUBECTL WITH /PROD/KUBERNETES-PROD

echo
echo "**** Running kubectl get nodes for /dev/kubernetes-dev"
echo
kubectl get nodes
