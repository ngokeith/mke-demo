#!/bin/bash

# Install Helm
echo make sure that you install Helm on your local machine
echo https://docs.helm.sh/using_helm/#installing-helm

echo if using macOS you can do:
echo brew install kubernetes-helm

# Create Kubernetes ServiceAccount for the Helm Tiller
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
EOF

# Install Tiller using Helm
helm init --service-account tiller

echo now you can run the ./deploy_istio.sh
