#!/bin/bash

echo
echo "**** Creating service account kubernetes-prod for use by /dev/kubernetes-dev"
echo
./modulescripts/setup_security_kubernetes-cluster.sh dev/kubernetes-dev kubernetes-dev dev/kubernetes-dev
echo
echo "**** Installing /dev/kubernetes-dev K8s cluster, v$1 using kubernetes-dev-options.json"
echo
dcos kubernetes cluster create --package-version=$1 --options=kubernetes-dev-options.json --yes
# dcos kubernetes cluster debug plan status deploy --cluster-name=dev/kubernetes-dev
