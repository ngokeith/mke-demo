#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kubernetes package version was not entered. Aborting."
        echo
        exit 1
fi

echo
echo "**** Creating service account kubernetes-uat for use by /uat/kubernetes-uat"
echo
./modulescripts/setup_security_kubernetes-cluster.sh uat/kubernetes-uat kubernetes-uat uat/kubernetes-uat
echo
echo "**** Installing /uat/kubernetes-uat K8s cluster, v2.2.0-1.13.3 using kubernetes-uat-options.json"
echo "     This cluster has 1 private kubelet, and 1 public kubelet"
echo
dcos kubernetes cluster create --package-version=2.2.0-1.13.3 --options=kubernetes-uat-options.json --yes
# dcos kubernetes cluster debug plan status deploy --cluster-name=uat/kubernetes-uat
