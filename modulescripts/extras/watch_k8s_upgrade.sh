#!/bin/bash

read -p "Input Kubernetes Cluster Path (i.e. prod/kubernetes-prod or dev/kubernetes-dev): " clusterid

watch dcos kubernetes cluster debug plan status deploy --cluster-name=$clusterid
