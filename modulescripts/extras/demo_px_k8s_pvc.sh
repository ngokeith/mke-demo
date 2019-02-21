#!/bin/bash

# Create PVC pod
read -p "Create the pvpod container? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl create -f pvc-pod.yaml
kubectl create -f pvc-pod.yaml
echo .
echo .
echo .
else
        echo no
fi

echo sleeping for 5 seconds to allow for container creation
sleep 5

# Describe PVC pod
read -p "Describe the pvpod? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl describe pod pvpod
kubectl describe pod pvpod
echo .
echo .
echo .
else
        echo no
fi

# Add entry to the PVC
read -p "Add entry 'foo' to /test-portworx-volume/test directory in the pvpod? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl exec -i pvpod -- /bin/sh -c "echo foo > /test-portworx-volume/test"
kubectl exec -i pvpod -- /bin/sh -c "echo foo > /test-portworx-volume/test"
echo .
echo .
echo .
else
        echo no
fi

# View entry
read -p "Validate entry in /test-portworx-volume/test directory exists in the pvpod? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl exec -i pvpod -- /bin/sh -c "cat /test-portworx-volume/test"
kubectl exec -i pvpod -- /bin/sh -c "cat /test-portworx-volume/test"
echo .
echo .
echo .
else
        echo no
fi

# Kill pod
echo Now you can delete the pod and deploy a new pod that uses the same PVC to show persistence.
echo
read -p "Kill the pvpod? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl delete pod pvpod
kubectl delete pod pvpod
echo .
echo .
echo .
else
        echo no
fi

# Create new Pod using the same PVC
read -p "Create a new pvpod2 using the same PVC? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl create -f pvc-pod2.yaml
kubectl create -f pvc-pod2.yaml
echo .
echo .
echo .
else
        echo no
fi
echo sleeping for 5 seconds to allow for container creation
sleep 5

# Validate
# View entry
read -p "Validate entry in /test-portworx-volume/test directory exists in the pvpod2? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl exec -i pvpod2 -- /bin/sh -c "cat /test-portworx-volume/test"
kubectl exec -i pvpod2 -- /bin/sh -c "cat /test-portworx-volume/test"
echo .
echo .
echo .
else
        echo no
fi

# Kill pod
echo
read -p "Kill the pvpod2? (y/n) " -n1 -s c
if [ "$c" = "y" ]; then
        echo yes

echo Using command:
echo kubectl delete pod pvpod2
kubectl delete pod pvpod2
echo .
echo .
echo .
else
        echo no
fi
