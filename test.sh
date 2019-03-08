#!/bin/bash

### Input service name
read -p "Input Framework Name (i.e. cassandra  kafka  elastic): " frameworkname

### Input service name
#read -p "Input Service Name (i.e. /dataservices/cassandra): " servicename

if [ $frameworkname = "kubernetes" ]; then

  echo yes

else
  echo no
fi
