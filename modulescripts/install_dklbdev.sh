#!/bin/bash

#### INSTALL DKLB
kubectl create -f dklb-prereqs.yaml
kubectl create -f dklb-deployment-dev.yaml
