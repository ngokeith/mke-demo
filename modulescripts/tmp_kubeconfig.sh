#!/bin/bash

#### MOVE EXISTING KUBE CONFIG FILE, IF ANY, AND DISPLAY KUBECTL VERSION

if [[ -e ~/.kube/config ]]; then
    echo
    echo "**** ~/.kube/config exists, moving it to /tmp/kubectl-config"
    echo "     And deleting any existing /tmp/kubectl-config"
    echo "     Therefore you now have no active kubectl config file"
    echo
    sudo rm -f /tmp/kubectl-config 2 > /dev/null
    sudo mv ~/.kube/config /tmp/kube-config
fi

echo
echo "**** Ensure your client version of kubectl is up to date, this is your 'kubectl version --short' output:"
echo "     Ignore the statement of 'The connection to the server localhost:8080 was refused'"
echo
kubectl version --short
echo
