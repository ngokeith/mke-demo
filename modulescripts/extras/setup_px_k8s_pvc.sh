#!/bin/bash

# Check to see that Portworx has finished installing
./modulescripts/check-status-with-name.sh portworx infra/storage/portworx

# Use Prod Context
kubectl config use-context prod

# Install Portworx Stork for K8s
kubectl apply -f "https://install.portworx.com/2.0?kbver=1.13.3&b=true&dcos=true&stork=true"

# Create a Kubernetes Storage Class for Portworx
cat <<EOF | kubectl create -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
   name: portworx-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "2"
EOF

# Define StorageClass as the default Storage Class in your K8s Cluster
kubectl patch storageclass portworx-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Create the Kubernetes Portworx PersistentVolumeClaim
cat <<EOF | kubectl create -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: pvc001
  annotations:
    volume.beta.kubernetes.io/storage-class: portworx-sc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

# Check status of the PVC:
kubectl describe pvc pvc001
