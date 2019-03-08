#!/bin/bash

### Input service name
read -p "Input Framework Name (i.e. cassandra  kafka  elastic  kubernetes): " frameworkname

### Input service name
read -p "Input Service Name (i.e. /dataservices/cassandra /dataservices/kafka  prod/kubernetes-prod dev/kubernetes-dev): " servicename

if [ $frameworkname = "kubernetes" ]; then

  read -p "Input options.json name (i.e. kubernetes-prod-scale-options.json): " optionspath

  ### Initiate Upgrade
  dcos kubernetes cluster update --options=$optionspath --cluster-name=$servicename

else

  ### Input package version
  read -p "Input optionsjson name (i.e. options-kafka.json): " optionspath

  ### Initiate upgrade
  dcos $frameworkname update start --options=$optionspath --name=$servicename
fi
