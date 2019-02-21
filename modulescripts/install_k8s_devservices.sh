#!/bin/bash

#### DEPLOY KAFKA PRODUCER ON KUBERNETES
#kubectl create -f kafka-producer.yaml

#### DEPLOY AND EXPOSE DCOS-SITE (1 and 2) APPS & HELLO-WORLD (1,2, and 3) APPS & REDIS using L4 TCP AND L7 HTTP
kubectl create -f multi-service-l4-dev.yaml
