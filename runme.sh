#!/bin/bash

######## REQUIRED VARIABLES ########

SCRIPT_VERSION="FEB-7-2019"
JENKINS_VERSION="3.5.2-2.107.2"
KAFKA_VERSION="2.3.0-1.1.0"
K8S_MKE_VERSION="stub-universe"
K8S_PROD_VERSION="stub-universe"
K8S_DEV_VERSION="stub-universe"
DCOS_USER="bootstrapuser"
DCOS_PASSWORD="deleteme"
EDGE_LB_VERSION="1.3.0"
# BELOW IS EDGELB VARS FOR BETA TESTING DKLB
#EDGE_LB_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb/stub-universe-edgelb.json"
#EDGE_LB_POOL_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb-pool/stub-universe-edgelb-pool.json"
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

echo "In the order below, this script will:"
echo
echo "1. Move existing DC/OS clusters into /tmp/dcos-clusters and set up a new cluster URL provided"
echo
echo "2. Update $LICENSE_FILE if it exists in the optional variables section if it exists"
echo
echo "3. Do an ssh-add on the $SSH_KEY_FILE in the optional variables section if it exists"
echo
echo "4. Move existing kube config to /tmp/kubectl-config so we can set up a new kube config"
echo
echo "5. Add repo and install Edge-LB - deploy kubectl pool once completed"
echo
echo "6. Set up Service Accounts and Install MKE Kubernetes engine"
echo
echo "7. Set up Service Accounts and Install /prod/kubernetes-prod cluster"
echo
echo "8. Set up Service Accounts and Install /dev/kubernetes-dev cluster"
echo
echo "9. Install Jenkins in /dev/jenkins"
echo
echo "10. Install Gitlab in /dev/gitlab-dev, expose gitlab-dev on your EDGELB_PUBLIC_AGENT_IP:10006"
echo
echo "11. Install Kafka - Create a topic called performancetest"
echo
echo "12. Wait for Kubernetes to complete deployment and connect clusters /dev/kubernetes-dev and /prod/kubernetes-prod using kubectl"
echo
echo "13. Deploy Kafka producer deployment `kafka-producer.yaml` on /prod/kubernetes-prod that sends data to Kafka"
echo
echo "14. Install DKLB (beta) for L4/L7 Ingress on MKE"
echo
echo "15. Multiple Hello World services, and multiple DC/OS Websites exposed on L4 and L7 through Edge-LB"
echo
echo "16. Create a prod-user in the prod group and a dev-user in the dev group both with the default DC/OS password"
echo
echo "17. Install dcos-monitoring and open up Grafana dashboard"
echo
echo "18. Open up L4/L7 services in your browser"
echo

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

#### New Links for Edge-LB stubs
#dcos package repo add --index=0 edgelb-aws $EDGE_LB_LINK

#dcos package repo add --index=0 edgelb-pool-aws $EDGE_LB_POOL_LINK

#### Old - for edgelb stable syntax:
dcos package repo add --index=0 edge-lb https://downloads.mesosphere.com/edgelb/v$EDGE_LB_VERSION/assets/stub-universe-edgelb.json
dcos package repo add --index=0 edge-lbpool https://downloads.mesosphere.com/edgelb-pool/v$EDGE_LB_VERSION/assets/stub-universe-edgelb-pool.json

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
sleep 20
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

#### INSTALL /DEV/GITLAB-DEV

echo
echo "**** Deploy Gitlab /dev/gitlab-dev"
dcos marathon app add gitlab-dev.json

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


#### WAIT FOR BOTH K8S CLUSTERS TO COMPLETE THEIR INSTALL

echo
echo "**** Testing if K8s install of /prod/kubernetes-prod is done,"
echo
# Sometimes I open another shell while waiting, since this is the biggest delay,
# so let's fix the dcos cli and kubectl now (and at the end of the script)
chown -RH $SUDO_USER ~/.kube ~/.dcos
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the public kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=prod/kubernetes-prod | grep kube-node-1 | awk '{print $4}'`;
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

#### GET PUBLIC IP OF EDGE-LB PUBLIC AGENT
echo
echo "**** Setting env var EDGELB_PUBLIC_AGENT_IP"
echo
export EDGELB_PUBLIC_AGENT_IP=$(dcos task exec -it kubectl-two-clusters__edgelb-pool- curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of Edge-LB node is: $EDGELB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

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

#### DEPLOY KAFKA PRODUCER ON /PROD/KUBERNETES-PROD
kubectl create -f kafka-producer.yaml

#### INSTALL DKLB
kubectl create -f dklb-prereqs.yaml
kubectl create -f dklb-deployment.yaml

#### DEPLOY AND EXPOSE DCOS-SITE (1 and 2) APPS & HELLO-WORLD (1,2, and 3) APPS & REDIS using L4 TCP
kubectl create -f multi-service-l4.yaml
kubectl create -f multi-service-l7.yaml

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

#### DEPLOY KAFKA PRODUCER ON /DEV/KUBERNETES-DEV
kubectl create -f kafka-producer.yaml

#### SHOW KUBECTL CONFIG

echo
echo "**** Running kubectl config get-clusters"
echo
kubectl config get-clusters
echo
echo "**** Changing kubectl context back to prod"
echo
kubectl config use-context prod

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
rm -f edge-lb-private-key.pem 2> /dev/null
rm -f edge-lb-public-key.pem 2> /dev/null

#### INSTALL DCOS-MONITORING
./install_monitoring.sh


# This script is ran via sudo since /etc/hosts is modified. But it also sets up kubectl and the dcos CLI
# which means some of those files now belong to root

echo
echo "**** Running chown -RH $SUDO_USER ~/.kube ~/.dcos since this script is ran via sudo"
echo
echo "If you ever break out of this script, you must run this command:"
chown -RH $SUDO_USER ~/.kube ~/.dcos

#### Opening dklb-pool-1 workloads
echo
echo "**** Setting env var DKLB_PUBLIC_AGENT_IP"
echo
export DKLB_PUBLIC_AGENT_IP=$(dcos task exec -it dcos-edgelb.pools.dklb curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $DKLB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### SETUP HOSTS FILE FOR mke-l7.ddns.net

echo
echo "**** Copying /etc/hosts to /tmp/hosts as a backup, deleting /tmp/hosts if it exists"
echo
rm -f /tmp/hosts 2> /dev/null
cp /etc/hosts /tmp

if [ -n "$(grep mke-l7.ddns.net /etc/hosts)" ]; then
    echo "**** mke-l7.ddns.net line found in /etc/hosts, removing that line";
    echo
    sed -i '' '/mke-l7.ddns.net/d' /etc/hosts
else
    echo "**** mke-l7.ddns.net was not found in /etc/hosts";
    echo
fi

if [ -n "$(grep dcos-gitlabdemo.ddns.net /etc/hosts)" ]; then
    echo "**** dcos-gitlabdemo.ddns.net line found in /etc/hosts, removing that line";
    echo
    sed -i '' '/dcos-gitlabdemo.ddns.net/d' /etc/hosts
else
    echo "**** dcos-gitlabdemo.ddns.net was not found in /etc/hosts";
    echo
fi

echo "**** Adding entries to /etc/hosts for mke-l7.ddns.net for $DKLB_PUBLIC_AGENT_IP"
echo "$DKLB_PUBLIC_AGENT_IP mke-l7.ddns.net" >> /etc/hosts
echo "$EDGELB_PUBLIC_AGENT_IP dcos-gitlabdemo.ddns.net" >> /etc/hosts
# to bypass DNS & hosts file: curl -H "Host: www.apache.test" $EDGELB_PUBLIC_AGENT_IP


echo
echo "     Opening your browser to $DKLB_PUBLIC_AGENT_IP:80,81,10001,10002"
echo
echo "     NOTE: If having connectivity issues, make sure that Public Agent LB is open for non 80/443 ports"
echo "     By default, CCM should have open security group rules for the ELB while the DCOS-terraform project only allows 80/443"
echo
echo
echo "     Here are the workloads below:"
echo "     L4 (TCP)  - hello-world1 service - port 10001"
echo "     L4 (TCP)  - dcos-site1 service   - port port 10002"
echo "     L7 (HTTP) - hello-world2 service - Defaults to http://mke-l7.ddns.net:80"
echo "     L7 (HTTP) - dcos-site2 service   - Defaults to http://mke-l7.ddns.net:81"
echo
#### WAIT FOR SERVICES TO BE EXPOSED BY EDGELB
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  if curl -s -H "Host: mke-l7.ddns.net" $DKLB_PUBLIC_AGENT_IP | grep -q "Hello"; then
      OUTPUT=0
  else
      printf "Waited $seconds seconds for L4/L7 services to be exposed. Still waiting.\n"
      sleep 15
  fi
done

#### OPEN WORKLOADS
echo "Opening workloads..."
echo
echo
open -na "/Applications/Google Chrome.app"/ http://$EDGELB_PUBLIC_AGENT_IP:10006
echo
open -na "/Applications/Google Chrome.app"/ http://$DKLB_PUBLIC_AGENT_IP:10001
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:80
sleep 1
open -na "/Applications/Google Chrome.app"/ http://$DKLB_PUBLIC_AGENT_IP:10002
sleep 1
open -na "/Applications/Google Chrome.app"/ http://mke-l7.ddns.net:81/docs/latest/
echo
echo
echo -e "To enable Mesos Metrics, if on CoreOS run \x1B[1m./start_vpn_coreos.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics_coreos.sh\x1B[0m in a seperate tab"
echo
echo -e "To enable Mesos Metrics, if on CentOS run \x1B[1m./start_vpn_centos.sh \x1B[0m before executing \x1B[1m./enable_mesos_metrics_centos.sh\x1B[0m in a seperate tab"
echo
echo "If you want to view the Kafka dashboard in Grafana, import dashboard 9018"
echo
echo
echo
