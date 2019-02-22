#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kubernetes package version was not entered. Aborting."
        echo
        exit 1
fi

echo
echo "**** Creating service account for MKE /kubernetes"
echo
./modulescripts/setup_security_kubernetes-cluster.sh kubernetes kubernetes kubernetes
echo
echo "**** Installing MKE /kubernetes"
echo
dcos package install kubernetes --package-version=$1 --options=kubernetes-mke-options.json --yes
# Might be redundant, but is harmless
dcos package install kubernetes --package-version=$1 --cli --yes
echo
echo "**** Sleeping for 20 seconds to wait for MKE to finish installing"
echo
sleep 20
