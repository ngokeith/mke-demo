#!/bin/bash

######## REQUIRED VARIABLES ########
SCRIPT_VERSION="FEB-15-2019"
JENKINS_VERSION="3.5.2-2.107.2"
KAFKA_VERSION="2.3.0-1.1.0"
K8S_MKE_VERSION="2.2.0-1.13.3"
K8S_PROD_VERSION="2.2.0-1.13.3"
K8S_DEV_VERSION="2.2.0-1.13.3"
DCOS_USER="bootstrapuser"
DCOS_PASSWORD="deleteme"
EDGE_LB_VERSION="1.3.0"
DCOS_MONITORING_VERSION="v0.4.2-beta"
# VHOST Routing Hostname for L7 Loadbalancing
VHOST="mke-l7.ddns.net"

######## OPTIONAL VARIABLES ########
LICENSE_FILE="<ALTERNATE/PATH/TO/LICENSE/FILE>"
SSH_KEY_FILE="<PATH/TO/SSH/KEY/FILE>"
USER="alexly"

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

./modulescripts/setup_cli.sh $MASTER_URL $DCOS_USER $DCOS_PASSWORD

#### UPDATE DC/OS LICENSE TO > CCM'S DEFAULT LICENSE

./modulescripts/update_license.sh $LICENSE_FILE

#### ADDING SSH KEY, EVEN THOUGH THIS SCRIPT DOESN'T USE IT

./modulescripts/setup_ssh.sh $SSH_KEY_FILE

#### CHANGE OWNERSHIP BACK TO USER
sudo chown -RH $USER ~/.kube ~/.dcos

#### CREATE AND ATTACH AWS EBS VOLUMES
#./modulescripts/create_and_attach_volumes.sh

#### INSTALL PORTWORX
#./modulescripts/setup_portworx_options.sh

#./modulescripts/install_portworx.sh

#### INSTALL EDGELB
./modulescripts/install_edgelb.sh $EDGE_LB_VERSION

#### DEPLOY EDGELB CONFIG FOR KUBECTL
./modulescripts/kubectl_edgelb.sh


#### ADD LATEST MKE STUB UNIVERSE that supports dklb
#dcos package repo add --index=0 kubernetes-aws "$KUBERNETES_STUB_LINK"

#dcos package repo add --index=0 kubernetes-cluster-aws "$KUBERNETES_CLUSTER_STUB_LINK"


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
./modulescripts/install_dklbprod.sh

#### DEPLOY SERVICES ON /PROD/KUBERNETES-PROD
./modulescripts/install_k8s_services.sh

#### SETUP KUBECTL FOR /DEV/KUBERNETES-DEV
./modulescripts/connect_k8sdev.sh

#### INSTALL DKLB ON /DEV/KUBERNETES-DEV
./modulescripts/install_dklbdev.sh

#### DEPLOY SERVICES ON /DEV/KUBERNETES-DEV
./modulescripts/install_k8s_devservices.sh

#### SHOW KUBECTL CONFIG

echo
echo "**** Running kubectl config get-clusters"
echo
kubectl config get-clusters
echo
echo "**** Changing kubectl context back to prod"
echo
kubectl config use-context prod

#### SETUP USER PROD-USER & GROUP PROD & SECRET /PROD/SECRET AND USER DEV-USER & GROUP DEV & SECRET /DEV/SECRET
./modulescripts/setup_RBAC.sh


#### REMOVE KEYS
rm -f private-key.pem 2> /dev/null
rm -f public-key.pem 2> /dev/null
rm -f edge-lb-private-key.pem 2> /dev/null
rm -f edge-lb-public-key.pem 2> /dev/null

#### INSTALL DCOS-MONITORING
./modulescripts/install_monitoring.sh $DCOS_MONITORING_VERSION

#### SETUP HOSTS FILE FOR mke-l7.ddns.net
echo may need your password to modify /etc/hosts
sudo ./modulescripts/append-etchosts.sh

#### OPEN WORKLOADS
./modulescripts/open_workloads.sh

# This script is ran via sudo since /etc/hosts is modified. But it also sets up kubectl and the dcos CLI
# which means some of those files now belong to root

echo
echo "**** Running chown -RH $USER ~/.kube ~/.dcos since this script is ran via sudo"
echo
echo "If you ever break out of this script, you must run this command:"
sudo chown -RH $USER ~/.kube ~/.dcos
echo
echo
