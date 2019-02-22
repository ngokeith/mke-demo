#!/bin/bash

### Check Kubernetes Package Versions
dcos kubernetes manager update package-versions

read -p "Input Package Version to Upgrade To: " pkgid

read -p "Input Cluster ID to Upgrade (i.e. prod/kubernetes-prod or dev/kubernetes-dev): " clusterid

### Initiate Upgrade
dcos kubernetes cluster update --package-version=$pkgid --cluster-name=$clusterid
