#!/bin/bash

### Input service name
read -p "Input Framework Name (i.e. cassandra  kafka  elastic  kubernetes): " frameworkname

### Input service name
read -p "Input Service Name (i.e. /dataservices/cassandra /dataservices/kafka  prod/kubernetes-prod dev/kubernetes-dev): " servicename

if [ $frameworkname = "kubernetes" ]; then

  watch dcos kubernetes cluster debug plan status deploy --cluster-name=$servicename

else

  watch dcos $frameworkname plan status deploy --name=$servicename

fi
