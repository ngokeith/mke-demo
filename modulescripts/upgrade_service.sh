#!/bin/bash

### Input service name
read -p "Input Framework Name (i.e. cassandra  kafka  elastic  kubernetes): " frameworkname

### Input service name
read -p "Input Service Name (i.e. /dataservices/cassandra /dataservices/kafka  prod/kubernetes-prod dev/kubernetes-dev): " servicename

if [ $frameworkname = "kubernetes" ]; then

  ### Check Kubernetes Package Versions
  dcos kubernetes manager update package-versions

  read -p "Input Package Version to Upgrade To: " pkgversion

  ### Initiate Upgrade
  dcos kubernetes cluster update --package-version="$pkgversion" --cluster-name=$servicename

else
  ### Display available upgrade/downgrade options
  dcos $frameworkname update package-versions --name=$servicename

  ### Input package version
  read -p "Input package version to upgrade/downgrade to: " pkgversion

  ### Initiate upgrade
  dcos $frameworkname update start --package-version="$pkgversion" --name=$servicename
fi
