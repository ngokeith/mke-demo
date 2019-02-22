#!/bin/bash

# Create a Kubernetes Deployment that will use the CSI PersistentVolumeClaim
read -p "Create a Kubernetes Deployment that will use the CSI PersistentVolumeClaim? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl create -f ebs-dynamic-app.yaml
kubectl create -f ebs-dynamic-app.yaml
echo .
echo .
echo .
else
        echo no
fi


# Check the content of the file /data/out.txt and note the first timestamp:
read -p "Check the content of the file /data/out.txt? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
echo kubectl exec -i $pod cat /data/out.txt
pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl exec -i $pod cat /data/out.txt
echo .
echo .
echo .
else
        echo no
fi

# Kill pod
read -p "Kill the ebs-dynamic-app pod? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl delete pod ebs-dynamic-app
kubectl delete pod ebs-dynamic-app
echo .
echo .
echo .
else
        echo no
fi

echo The Deployment will recreate the pod automatically.

echo Check the content of the file /data/out.txt and verify that the first timestamp is the same as the one noted previously:

# Check the content of the file /data/out.txt and note the first timestamp:
read -p "Check the content of the file /data/out.txt? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
echo kubectl exec -i $pod cat /data/out.txt
pod=$(kubectl get pods | grep ebs-dynamic-app | awk '{ print $1 }')
kubectl exec -i $pod cat /data/out.txt
echo .
echo .
echo .
else
        echo no
fi
