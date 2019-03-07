#!/bin/bash

read -p "Input kubernetes cluster name (i.e. dev/kubernetes-dev  prod/kubernetes-prod): " clustername
echo
echo "Using kubernetes cluster: $clustername"
echo
read -p "Input path to options.json relative to folder (i.e. kubernetes-prod-scale-options.json): " options
echo
echo "options.json path is $options"
echo
dcos kubernetes cluster update --cluster-name=$clustername --options=$options
echo
