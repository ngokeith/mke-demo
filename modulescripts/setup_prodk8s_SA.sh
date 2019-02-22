#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kubernetes package version was not entered. Aborting."
        echo
        exit 1
fi

echo
echo "**** Creating service account kubernetes-prod for use by /prod/kubernetes-prod"
echo
./modulescripts/setup_security_kubernetes-cluster.sh prod/kubernetes-prod kubernetes-prod prod/kubernetes-prod
echo
echo "**** Installing /prod/kubernetes-prod K8s cluster, v$1 using kubernetes-prod-options.json"
echo "     This cluster has 1 private kubelet, and 1 public kubelet"
echo
dcos kubernetes cluster create --package-version=$1 --options=kubernetes-prod-options.json --yes
# dcos kubernetes cluster debug plan status deploy --cluster-name=prod/kubernetes-prod
