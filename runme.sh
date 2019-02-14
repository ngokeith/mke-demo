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
DCOS_MONITORING_VERSION="v0.4.2-beta"
# BELOW IS MKE VARS FOR BETA TESTING DKLB
KUBERNETES_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes/master/stub-universe-kubernetes.json"
KUBERNETES_CLUSTER_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes-cluster/master/stub-universe-kubernetes-cluster.json"
# VHOST Routing Hostname for L7 Loadbalancing
VHOST="mke-l7.ddns.net"

######## OPTIONAL VARIABLES ########
LICENSE_FILE="dcos-1-12-license-50-nodes.txt"
SSH_KEY_FILE="/Users/josh/ccm-priv.key"

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

#### MOVE DCOS CLI CLUSTERS TO /TMP/CLUSTERS
./modulescripts/tmp_clusters.sh

#### MOVE EXISTING KUBE CONFIG FILE, IF ANY, AND DISPLAY KUBECTL VERSION
./modulescripts/tmp_kubeconfig.sh

#### EXPLAIN WHAT THIS SCRIPT WILL DO
./modulescripts/echo_explanation.sh

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

#### CHANGE OWNERSHIP BACK TO USER
sudo chown -RH $USER ~/.kube ~/.dcos

#### INSTALL EDGELB
./modulescripts/install_edgelb.sh $EDGE_LB_VERSION

#### DEPLOY EDGELB CONFIG FOR KUBECTL
./modulescripts/kubectl_edgelb.sh


#### ADD LATEST MKE STUB UNIVERSE that supports dklb
dcos package repo add --index=0 kubernetes-aws "$KUBERNETES_STUB_LINK"

dcos package repo add --index=0 kubernetes-cluster-aws "$KUBERNETES_CLUSTER_STUB_LINK"


#### SETUP AND INSTALL MKE /kubernetes
./modulescripts/install_mke.sh $K8S_MKE_VERSION

#### SETUP SERVICE ACCOUNT FOR /PROD/KUBERNETES-PROD AND INSTALL K8S
./modulescripts/setup_prodk8s_SA.sh $K8S_DEV_VERSION

#### SETUP SERVICE ACCOUNT FOR /DEV/KUBERNETES-DEV AND INSTALL K8S
./modulescripts/setup_devk8s_SA.sh $K8S_DEV_VERSION

#### INSTALL /DEV/JENKINS
./modulescripts/install_jenkins.sh $JENKINS_VERSION

#### INSTALL /DEV/GITLAB-DEV
./modulescripts/install_gitlab.sh

#### INSTALL KAFKA
./modulescripts/install_kafka.sh $KAFKA_VERSION

#### CREATE KAFKA TOPIC
dcos kafka topic create performancetest --partitions 10 --replication 3 --name=kafka

#### WAIT FOR BOTH K8S CLUSTERS TO COMPLETE THEIR INSTALL
./modulescripts/test_k8s.sh

#### CONNECT TO /PROD/KUBERNETES-PROD USING KUBECTL
./modulescripts/connect_k8sprod.sh

#### INSTALL DKLB ON /PROD/KUBERNETES-PROD
./modulescripts/install_dklb.sh

#### DEPLOY SERVICES ON /PROD/KUBERNETES-PROD
./modulescripts/install_k8s_services.sh

#### SETUP KUBECTL FOR /DEV/KUBERNETES-DEV
./modulescripts/connect_k8sdev.sh

#### INSTALL DKLB ON /DEV/KUBERNETES-DEV
#./modulescripts/install_dklb.sh

#### DEPLOY SERVICES ON /DEV/KUBERNETES-DEV
#./modulescripts/install_k8s_devservices.sh

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
#./modulescripts/RBAC_secrets.sh

#### CLEANUP, FIX DCOS CLI AND KUBECTL FILE OWNERSHIP BECAUSE OF SUDO

rm -f private-key.pem 2> /dev/null
rm -f public-key.pem 2> /dev/null
rm -f edge-lb-private-key.pem 2> /dev/null
rm -f edge-lb-public-key.pem 2> /dev/null

#### INSTALL DCOS-MONITORING
./modulescripts/install_monitoring.sh $DCOS_MONITORING_VERSION


# This script is ran via sudo since /etc/hosts is modified. But it also sets up kubectl and the dcos CLI
# which means some of those files now belong to root

#echo
#echo "**** Running chown -RH $USER ~/.kube ~/.dcos since this script is ran via sudo"
#echo
#echo "If you ever break out of this script, you must run this command:"
#chown -RH $USER ~/.kube ~/.dcos
#echo
#echo
#### SETUP HOSTS FILE FOR mke-l7.ddns.net
echo may need your password to modify /etc/hosts
sudo ./modulescripts/append-etchosts.sh

#### OPEN WORKLOADS
./modulescripts/open_workloads.sh

#### CHANGE OWNERSHIP BACK TO USER AGAIN FOR SAFE MEASURE
sudo chown -RH $USER ~/.kube ~/.dcos
