
#!/bin/bash

./modulescripts/setup_security_kubernetes-cluster.sh uat/kubernetes-uat kubernetes-uat uat/kubernetes-uat

region=us-east-1
version=2.1.1-1.12.5

sed "s/REGION/${region}/g" kubernetes-uat-options.json.template > kubernetes-uat-options.json

dcos kubernetes cluster create --package-version=$version --options=kubernetes-uat-options.json --yes
