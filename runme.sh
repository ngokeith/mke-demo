#!/bin/bash

###### TEMPORARY SECTION
# list files, document their differences
# todo: pull in other todos, version
# what permissions does MKE need in its service account? is it for a team's k8s, or for all k8s?
# new prod: rbac, controplane cpu lowered to 0.5, priv reserved kube cpus lowered to 1, public node count raised to 1,
# incorporate k8s autoscaler demo


######## REQUIRED VARIABLES ########

SCRIPT_VERSION="JAN-30-2019"
JENKINS_VERSION="3.5.2-2.107.2"
KAFKA_VERSION="2.3.0-1.1.0"
K8S_MKE_VERSION="stub-universe"
K8S_PROD_VERSION="stub-universe"
K8S_DEV_VERSION="stub-universe"
DCOS_USER="bootstrapuser"
DCOS_PASSWORD="deleteme"
#KEEP FOR OLD STABLE - EDGE_LB_VERSION="1.2.3-42-g6643742"
# BELOW IS EDGELB VARS FOR BETA TESTING DKLB
EDGE_LB_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb/stub-universe-edgelb.json"
EDGE_LB_POOL_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb-pool/stub-universe-edgelb-pool.json"
# BELOW IS MKE VARS FOR BETA TESTING DKLB
KUBERNETES_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes/master/stub-universe-kubernetes.json"
KUBERNETES_CLUSTER_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes-cluster/master/stub-universe-kubernetes-cluster.json"
# VHOST Routing Hostname for L7 Loadbalancing
VHOST="mke-l7.ddns.net"

######## OPTIONAL VARIABLES ########
LICENSE_FILE="dcos-1-12-license-50-nodes.txt"
SSH_KEY_FILE="/Users/josh/ccm-priv.key"

#### TEST IF RAN AS ROOT

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root, via sudo"
   exit 1
fi

#### SETUP MASTER URL VARIABLE

# NOTE: elb url is not used in this script (yet) TODO
if [[ $1 == "" ]]
then
        echo
        echo " A master node's URL was not entered. Aborting."
        echo
        exit 1
fi

# For the master change http to https so kubectl setup doesn't break
MASTER_URL=$(echo $1 | sed 's/http/https/')

#### EXPLAIN WHAT THIS SCRIPT WILL DO

echo
echo
echo "Script version $SCRIPT_VERSION"
echo
echo "This script will install:"
echo
echo "  1. Edge-LB v$EDGE_LB_VERSION"
echo
echo "  2. Kubernetes (MKE) v$K8S_MKE_VERSION"
echo
echo "  3. A v$K8S_PROD_VERSION K8s cluster named /prod/kubernetes-prod"
echo "     this cluster will have 1 public node which will run traefik,"
echo "     and 1 private node running apache and NGINX"
echo
echo "  4. A v$K8S_DEV_VERSION K8s cluster named /dev/kubernetes-dev"
echo
echo "  5. A v$KAFKA_VERSION Kafka named kafka and a load generator to show kafka metrics in Grafana"
echo
echo "  6. A license file named $LICENSE_FILE, if it exists"
echo
echo "  7. The SSH key $SSH_KEY_FILE via ssh-add, if it exists"
echo
echo "  8. A v$JENKINS_VERSION Jenkins named /dev/jenkins"
echo
echo "Your existing kubectl config file will be moved to /tmp/kubectl-config"
echo
echo "Your existing DC/OS cluster configs will be moved to /tmp/clusters"
echo "  because of a bug (that might be fixed) when too many clusters are defined."
echo
echo "The DC/OS CLI and kubectl must already be installed, it will be configured for the cluster at"
echo "$MASTER_URL"
echo "with user name $DCOS_USER and password $DCOS_PASSWORD"
echo
echo "The user name that ran this script is $USER so file ownership for kubectl and DC/OS CLI files will be chown'ed to $SUDO_USER"

#### MOVE DCOS CLI CLUSTERS TO /TMP/CLUSTERS

echo
echo "**** Moving DC/OS CLI configuration to /tmp/dcos-clusters"
echo "     So all existing DC/OS cluster configurations are now removed"
echo
rm -rf /tmp/dcos-clusters 2> /dev/null
mkdir /tmp/dcos-clusters
mv ~/.dcos/clusters/* /tmp/dcos-clusters 2> /dev/null
mv ~/.dcos/dcos.toml /tmp/dcos-clusters 2> /dev/null
rm -rf ~/.dcos 2> /dev/null

#### SETUP CLI

echo
echo "**** Running command: dcos cluster setup"
#echo
dcos cluster setup $MASTER_URL --insecure --username=$DCOS_USER --password=$DCOS_PASSWORD
echo
echo "**** Installing enterprise CLI"
echo
dcos package install dcos-enterprise-cli --yes
echo
echo "**** Setting core.ssl_verify to false"
echo
dcos config set core.ssl_verify false

#### UPDATE DC/OS LICENSE TO > CCM'S DEFAULT LICENSE

if [[ -e $LICENSE_FILE ]]; then
    echo
    echo "**** Updating DC/OS license using $LICENSE_FILE"
    echo
    dcos license renew $LICENSE_FILE
else
    echo
    echo "**** License file $LICENSE_FILE not found, license will not be updated"
    echo
fi

#### ADDING SSH KEY, EVEN THOUGH THIS SCRIPT DOESN'T USE IT

if [[ -e $SSH_KEY_FILE ]]; then
    echo
    echo "**** Adding SSH key $SSH_KEY_FILE to this workstation's SSH keychain"
    echo
    ssh-add $SSH_KEY_FILE
else
    echo
    echo "**** SSH key $SSH_KEY_FILE not found, no key will be added to this workstation's SSH keychain"
    echo
fi

#### MOVE EXISTING KUBE CONFIG FILE, IF ANY, AND DISPLAY KUBECTL VERSION

if [[ -e ~/.kube/config ]]; then
    echo
    echo "**** ~/.kube/config exists, moving it to /tmp/kubectl-config"
    echo "     And deleting any existing /tmp/kubectl-config"
    echo "     Therefore you now have no active kubectl config file"
    echo
    rm -f /tmp/kubectl-config 2 > /dev/null
    mv ~/.kube/config /tmp/kube-config
fi

echo
echo "**** Ensure your client version of kubectl is up to date, this is your 'kubectl version --short' output:"
echo "     Ignore the statement of 'The connection to the server localhost:8080 was refused'"
echo
kubectl version --short
echo

#### INSTALL EDGE-LB

echo
echo "**** Installing Edge-LB v$EDGE_LB_VERSION"
echo

#### New Links for Edge-LB version with dklb support
dcos package repo add --index=0 edgelb-aws $EDGE_LB_LINK

dcos package repo add --index=0 edgelb-pool-aws $EDGE_LB_POOL_LINK

#### Old - for edgelb stable syntax:
#dcos package repo add --index=0 edge-lb https://downloads.mesosphere.com/edgelb/v$EDGE_LB_VERSION/assets/stub-universe-edgelb.json
#dcos package repo add --index=0 edge-lbpool https://downloads.mesosphere.com/edgelb-pool/v$EDGE_LB_VERSION/assets/stub-universe-edgelb-pool.json

rm -f /tmp/edge-lb-private-key.pem 2> /dev/null
rm -f /tmp/edge-lb-public-key.pem 2> /dev/null
# CHANGE: commented out two lines
dcos security org service-accounts keypair /tmp/edge-lb-private-key.pem /tmp/edge-lb-public-key.pem
dcos security org service-accounts create -p /tmp/edge-lb-public-key.pem -d "Edge-LB service account" edge-lb-principal
# dcos security org service-accounts show edge-lb-principal
# TODO DEBUG Getting error on next line, says it already exists, assuming it was added for a strict mode cluster?
dcos security secrets create-sa-secret --strict /tmp/edge-lb-private-key.pem edge-lb-principal dcos-edgelb/edge-lb-secret
# TODO DEBUG Getting error on next line, says already part of group
dcos security org groups add_user superusers edge-lb-principal

# TODO: later add --package-version, it doesn't work at the moment
dcos package install --options=edgelb-options.json edgelb --yes
# Is redundant but harmless
dcos package install edgelb --cli --yes

#### WAIT FOR EDGE-LB TO INSTALL

# This is done now so the next section that needs user input to get the sudo password can happen
# sooner rather than later, so you can walk away and let the script run after
echo
echo "**** Waiting for Edge-LB to install"
echo
sleep 30
echo "     Ignore any 404 errors on next line that begin with  dcos-edgelb: error: Get https://"
until dcos edgelb ping; do sleep 3 & echo "still waiting..."; done

#### DEPLOY EDGELB CONFIG FOR KUBECTL

echo
echo "**** Deploying Edge-LB config from edgelb-kubectl-two-clusters.json"
echo
dcos edgelb create edgelb-kubectl-two-clusters.json
echo
echo "**** Sleeping for 30 seconds since it takes some time for Edge-LB's config to load"
echo
sleep 30
echo
echo "**** Running dcos 'edgelb status edgelb-kubectl-two-clusters'"
echo
dcos edgelb status edgelb-kubectl-two-clusters
#echo
#echo "**** Running 'dcos edgelb show edgelb-kubectl-two-clusters'"
#echo
#dcos edgelb show edgelb-kubectl-two-clusters

#### GET PUBLIC IP OF EDGE-LB PUBLIC AGENT

# This is a real hack, and it might not work correctly!
echo
echo "**** Setting env var EDGELB_PUBLIC_AGENT_IP using a hack of a method"
echo
export EDGELB_PUBLIC_AGENT_IP=$(dcos task exec -it edgelb-pool-0-server curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $EDGELB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip


#### ADD LATEST MKE STUB UNIVERSE that supports dklb
dcos package repo add --index=0 kubernetes-aws "$KUBERNETES_STUB_LINK"

dcos package repo add --index=0 kubernetes-cluster-aws "$KUBERNETES_CLUSTER_STUB_LINK"


#### SETUP AND INSTALL MKE /kubernetes

echo
echo "**** Creating service account for MKE /kubernetes"
echo
bash setup_security_kubernetes-cluster.sh kubernetes kubernetes kubernetes
echo
echo "**** Installing MKE /kubernetes"
echo
dcos package install kubernetes --package-version=$K8S_MKE_VERSION --options=kubernetes-mke-options.json --yes
# Might be redundant, but is harmless
dcos package install kubernetes --package-version=$K8S_MKE_VERSION --cli --yes
echo
echo "**** Sleeping for 20 seconds to wait for MKE to finish installing"
echo
sleep 20

#### SETUP SERVICE ACCOUNT FOR /PROD/KUBERNETES-PROD AND INSTALL K8S

echo
echo "**** Creating service account kubernetes-prod for use by /prod/kubernetes-prod"
echo
bash setup_security_kubernetes-cluster.sh prod/kubernetes-prod kubernetes-prod prod/kubernetes-prod
echo
echo "**** Installing /prod/kubernetes-prod K8s cluster, v$K8S_PROD_VERSION using kubernetes-prod-options.json"
echo "     This cluster has 1 private kubelet, and 1 public kubelet"
echo
dcos kubernetes cluster create --package-version=$K8S_PROD_VERSION --options=kubernetes-prod-options.json --yes
# dcos kubernetes cluster debug plan status deploy --cluster-name=prod/kubernetes-prod

#### SETUP SERVICE ACCOUNT FOR /DEV/KUBERNETES-DEV AND INSTALL K8S

echo
echo "**** Creating service account kubernetes-prod for use by /dev/kubernetes-dev"
echo
bash setup_security_kubernetes-cluster.sh dev/kubernetes-dev kubernetes-dev dev/kubernetes-dev
echo
echo "**** Installing /dev/kubernetes-dev K8s cluster, v$K8S_DEV_VERSION using kubernetes-dev-options.json"
echo
dcos kubernetes cluster create --package-version=$K8S_DEV_VERSION --options=kubernetes-dev-options.json --yes
# dcos kubernetes cluster debug plan status deploy --cluster-name=dev/kubernetes-dev

#### INSTALL /DEV/JENKINS

echo
echo "**** Installing Jenkins v$JENKINS_VERSION to /dev"
echo
dcos package install jenkins --package-version=$JENKINS_VERSION --options=jenkins-options.json --yes

#### INSTALL KAFKA
KAFKA_VERSION="2.3.0-1.1.0"

#### INSTALL KAFKA
echo
echo "**** Installing kafka v$KAFKA_VERSION"
echo
dcos package install kafka --package-version=$KAFKA_VERSION --options=options-kafka.json --yes
sleep 20
seconds=20
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the public kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kafka plan status deploy --name=kafka | grep kafka-2 | awk '{print $3}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kafka to start. Still waiting.\n"
  sleep 10
done

dcos kafka topic create performancetest --partitions 10 --replication 3 --name=kafka

dcos marathon app add 250-baseline.json


#### WAIT FOR BOTH K8S CLUSTERS TO COMPLETE THEIR INSTALL

echo
echo "**** Sleeping for 30 seconds before testing if K8s install of /prod/kubernetes-prod is done,"
echo "     since it takes a while for kubernetes to be installed (~ 360 seconds)"
echo
# Sometimes I open another shell while waiting, since this is the biggest delay,
# so let's fix the dcos cli and kubectl now (and at the end of the script)
chown -RH $SUDO_USER ~/.kube ~/.dcos
sleep 30
seconds=30
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the public kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=prod/kubernetes-prod | grep kube-node-0 | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kubernetes to start. Still waiting.\n"
  sleep 10
done

echo
echo "**** /prod/kubernetes-prod install complete"
echo
echo "**** Waiting for /dev/kubernetes-dev to install"
echo
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kubernetes to start. Still waiting.\n"
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=dev/kubernetes-dev | grep kube-node-0 | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  sleep 10
done
echo
echo "**** /dev/kubernetes-dev install complete"
echo

#### SETUP KUBECTL FOR /PROD/KUBERNETES-PROD

echo
echo "**** Running dcos kubernetes cluster kubeconfig for /prod/kubernetes-prod, as context 'prod'"
echo
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=prod --cluster-name=prod/kubernetes-prod --apiserver-url=https://$EDGELB_PUBLIC_AGENT_IP:6443

#### TEST KUBECTL WITH /PROD/KUBERNETES-PROD

echo
echo "**** Running kubectl get nodes for /prod/kubernetes-prod"
echo
kubectl get nodes


#### INSTALL DKLB
kubectl create -f dklb-prereqs.yaml
kubectl create -f dklb-deployment.yaml

#### DEPLOY AND EXPOSE DCOS-SITE (1 and 2) APPS & HELLO-WORLD (1,2, and 3) APPS & REDIS using L4 TCP
kubectl create -f multi-service-l4.yaml

#### DEPLOY AND EXPOSE DCOS-SITE (3 and 4) APPS & HELLO-WORLD (4 and 5) APPS using L7 TCP
cat <<EOF >> l7-ingress.yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: dklb
    kubernetes.dcos.io/edgelb-pool-port: "80"
  labels:
    owner: dklb
  name: helloworld4-ig
spec:
  rules:
  - host: "$VHOST"
    http:
      paths:
      - backend:
          serviceName: hello-world4
          servicePort: 80
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: dklb
    kubernetes.dcos.io/edgelb-pool-port: "81"
  labels:
    owner: dklb
  name: helloworld5-ig
spec:
  rules:
  - host: "$VHOST"
    http:
      paths:
      - backend:
          serviceName: hello-world5
          servicePort: 80
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: edgelb
    kubernetes.dcos.io/edgelb-pool-name: dklb
    kubernetes.dcos.io/edgelb-pool-port: "82"
  labels:
    owner: dklb
  name: dcos-site3
spec:
  rules:
  - host: "$VHOST"
    http:
      paths:
      - backend:
          serviceName: dcos-site3
          servicePort: 80
EOF

kubectl create -f l7-ingress.yaml

#### SETUP KUBECTL FOR /DEV/KUBERNETES-DEV

echo
echo "**** Running dcos kubernetes cluster kubeconfig for /dev/kubernetes-dev, as context 'dev'"
echo
dcos kubernetes cluster kubeconfig --insecure-skip-tls-verify --context-name=dev --cluster-name=dev/kubernetes-dev --apiserver-url=https://$EDGELB_PUBLIC_AGENT_IP:6444

#### TEST KUBECTL WITH /DEV/KUBERNETES-DEV

echo
echo "**** Running kubectl get nodes for /dev/kubernetes-dev"
echo
kubectl get nodes

#### SHOW KUBECTL CONFIG

echo
echo "**** Running kubectl config get-clusters"
echo
kubectl config get-clusters
echo
echo "**** Changing kubectl context back to prod"
echo
kubectl config use-context prod

#### INSTALL BINARY SECRET TO DC/OS (NOT K8S)

echo
echo "**** Adding binary secret /binary-secret to DC/OS's secret store"
echo "     To display it: dcos security secrets get /binary-secret"
echo
dcos security secrets create /binary-secret --file binary-secret.txt

#### SETUP USER PROD-USER & GROUP PROD & SECRET /PROD/SECRET

echo
echo
echo "**** Creating DC/OS user prod-user, group prod, secret /prod/example-secret, and example app"
echo
dcos security org users create prod-user --password=deleteme
dcos security org groups create prod
dcos security org groups add_user prod prod-user
dcos security secrets create /prod/example-secret --value="prod-team-secret"
dcos security org groups grant prod dcos:secrets:list:default:/prod full
dcos security org groups grant prod dcos:secrets:default:/prod/* full
dcos security org groups grant prod dcos:service:marathon:marathon:services:/prod full
dcos security org groups grant prod dcos:adminrouter:service:marathon full
# Appears to be necessary per COPS-2534
dcos security org groups grant prod dcos:secrets:list:default:/ read
# Make the marathon folder by making the app
dcos marathon app add prod-example-marathon-app.json

#### SETUP USER DEV-USER & GROUP DEV & SECRET /DEV/SECRET

echo
echo "**** Creating DC/OS user dev-user, group dev, secret /dev/example-secret, and example app"
echo
dcos security org users create dev-user --password=deleteme
dcos security org groups create dev
dcos security org groups add_user dev dev-user
dcos security secrets create /dev/example-secret --value="dev-team-secret"
dcos security org groups grant dev dcos:secrets:list:default:/dev full
dcos security org groups grant dev dcos:secrets:default:/dev/* full
dcos security org groups grant dev dcos:service:marathon:marathon:services:/dev full
dcos security org groups grant dev dcos:adminrouter:service:marathon full
# Appears to be necessary per COPS-2534
dcos security org groups grant dev dcos:secrets:list:default:/ read

#### CLEANUP, FIX DCOS CLI AND KUBECTL FILE OWNERSHIP BECAUSE OF SUDO

rm -f private-key.pem 2> /dev/null
rm -f public-key.pem 2> /dev/null

# This script is ran via sudo since /etc/hosts is modified. But it also sets up kubectl and the dcos CLI
# which means some of those files now belong to root

echo
echo "**** Running chown -RH $SUDO_USER ~/.kube ~/.dcos since this script is ran via sudo"
echo
# If you ever break out of this script, you must run this command:
chown -RH $SUDO_USER ~/.kube ~/.dcos

#### INSTALL DCOS-MONITORING
./install_monitoring.sh

#### Opening dklb-pool-1 workloads
echo "     Sleeping for 30 seconds to make sure sufficient time has been given for the app and Edgelb pool to deploy"
sleep 30
echo
echo "**** Setting env var DKLB_PUBLIC_AGENT_IP"
echo
export DKLB_PUBLIC_AGENT_IP=$(dcos task exec -it dcos-edgelb.pools.dklb curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $DKLB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

echo "     Opening your browser to $DKLB_PUBLIC_AGENT_IP:80,8080,8181,10004,10005"
echo "     NOTE: If having connectivity issues, make sure that Public Agent LB is open for non 80/443 ports"
echo "     By default, CCM should have open security group rules for the ELB while the DCOS-terraform project only allows 80/443"
echo
echo
echo "     Here are the workloads below:"
echo "     L4 (TCP) - hello-world1 service - port 10001"
echo "     L4 (TCP) - hello-world2 service - port 10002"
echo "     L4 (TCP) - hello-world3 service - port 10003"
echo "     L7 (HTTP) - hello-world4 service - Defaults to http://mke-l7.ddns.net:80"
echo "     L7 (HTTP) - hello-world5 service - Defaults to http://mke-l7.ddns.net:81"
echo "     L4 (TCP) - dcos-site1 service - port 10004"
echo "     L4 (TCP) - dcos-site2 service - port 10005"
echo "     L7 (HTTP) - dcos-site3 service - Defaults to http://mke-l7.ddns.net:82"

open "http://$DKLB_PUBLIC_AGENT_IP:10001"

echo -e "To enable Mesos Metrics, run \x1B[1m./start_vpn.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics.sh\x1B[0m"

echo "     If you want to view the Kafka dashboard in Grafana, import dashboard 9018"
