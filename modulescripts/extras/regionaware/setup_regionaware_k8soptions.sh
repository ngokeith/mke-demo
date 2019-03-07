
#!/bin/bash

./modulescripts/setup_security_kubernetes-cluster.sh uat/kubernetes-uat kubernetes-uat uat/kubernetes-uat

read -p "Input kubernetes cluster region (i.e. us-west-2 or us-east-1): " region

sed "s/REGION/${region}/g" kubernetes-uat-options.json.template > kubernetes-uat-options.json

read -p "Input kubernetes version (i.e. 2.2.0-1.13.3 or 2.1.1-1.12.5): " version

dcos kubernetes cluster create --package-version=$version --options=kubernetes-uat-options.json --yes
