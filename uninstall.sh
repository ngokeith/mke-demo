#!/bin/bash
kubectl config use-context prod # kubectx prod
kubectl delete -f multi-service-l7.yaml
sleep 15
kubectl delete -f kafka-producer.yaml
kubectl delete -f dklb-deployment-dev.yaml
kubectl delete -f dklb-prereqs.yaml

kubectl config use-context dev # kubectx dev

kubectl delete -f multi-service-l4-dev.yaml
sleep 15
kubectl delete -f dklb-deployment-prod.yaml
kubectl delete -f dklb-prereqs.yaml

kubectl config use-context uat # kubectx uat
kubectl delete -f kafka-producer-uat.yaml

dcos edgelb delete kubectl-pool
dcos edgelb delete services-pool


dcos package uninstall kafka --yes --app-id=kafka

dcos package uninstall kafka --yes --app-id=useast1-kafka

dcos package uninstall beta-dcos-monitoring --yes

dcos package uninstall cassandra --yes

dcos package uninstall hdfs --yes

dcos package uninstall portworx-hadoop --yes

dcos package uninstall jupyterlab --yes

dcos kubernetes cluster delete --cluster-name=dev/kubernetes-dev --yes

dcos kubernetes cluster delete --cluster-name=prod/kubernetes-prod --yes

dcos kubernetes cluster delete --cluster-name=uat/kubernetes-uat --yes

dcos marathon app remove dev/gitlab-dev

dcos marathon app remove dev/dev-jenkins

echo now run: dcos package uninstall kubernetes --yes

echo now run: dcos package uninstall edgelb --yes
