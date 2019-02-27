#!/bin/bash

# This script is ran via sudo since /etc/hosts is modified. But it also sets up kubectl and the dcos CLI
# which means some of those files now belong to root
# If you ever break out of this script,this command is run to return permissions from sudo
# sudo chown -RH $USER ~/.kube ~/.dcos

function finish {
  sudo chown -RH $USER ~/.kube ~/.dcos
}
trap finish EXIT

SCRIPT_VERSION="FEB-25-2019"

######## REQUIRED VARIABLES ########
JENKINS_VERSION="3.5.2-2.107.2"
KAFKA_VERSION="2.3.0-1.1.0"
K8S_MKE_VERSION="2.2.0-1.13.3"
K8S_PROD_VERSION="2.2.0-1.13.3"
K8S_DEV_VERSION="2.1.1-1.12.5"
DCOS_USER="bootstrapuser"
DCOS_PASSWORD="deleteme"
EDGE_LB_VERSION="1.3.0"
DCOS_MONITORING_VERSION="v0.4.3-beta"
# VHOST Routing Hostname for L7 Loadbalancing
VHOST="mke-l7.ddns.net"

######## OPTIONAL VARIABLES ########
#
# MAKE SURE YOU HAVE ENOUGH EXTRA RESOURCES IN YOUR CLUSTER IF YOU SET BELOW TO TRUE
#
# IF ALL FEATURES ARE SET TO TRUE YOU WILL NEED A TOTAL OF AT LEAST 49.3 CPU shares:
# 7 8vCPU Private Agents
# 1 4vCPU Public Agent
#
#
# PORTWORX INSTALLATION FOR 7 PRIVATE AGENT NODES CAN TAKE UP TO 10-15 ADDITIONAL MINUTES
PORTWORX_ENABLED="false"
JUPYTERLAB_ENABLED="false"
# HDFS Requires minimum 6 Private Agent nodes in your cluster
HDFS_ENABLED="false"
CASSANDRA_ENABLED="false"

# OPTIONAL PACKAGE VERSIONS
PORTWORX_VERSION="1.3.3-1.6.1.1"
CASSANDRA_VERSION="2.3.0-3.0.16"
HDFS_VERSION="2.5.0-2.6.0-cdh5.11.0"
PORTWORX_HDFS_VERSION="1.2-2.6.0"
JUPYTERLAB_VERSION="1.2.0-0.33.7"

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

#### INSTALL HDFS
if [ "$HDFS_ENABLED" = "true" ] && [ "$PORTWORX_ENABLED" = "false" ]; then

  ./modulescripts/install_hdfs.sh $HDFS_VERSION

  sleep 10

  ./modulescripts/install_cli.sh hdfs

  ./modulescripts/check-status-with-name.sh hdfs hdfs 300

fi

#### INSTALL PORTWORX
if [ "$PORTWORX_ENABLED" = "true" ] && [ "$HDFS_ENABLED" = "false" ]; then
  #### CREATE AND ATTACH AWS EBS VOLUMES
  ./modulescripts/create_and_attach_volumes.sh

  #### INSTALL PORTWORX
  ./modulescripts/setup_portworx_options.sh

  ./modulescripts/install_portworx.sh $PORTWORX_VERSION

  ./modulescripts/install_cli.sh portworx

  sleep 10

  ./modulescripts/check-status-with-name.sh portworx /infra/storage/portworx 600-900

fi

if [ "$PORTWORX_ENABLED" = "true" ] && [ "$HDFS_ENABLED" = "true" ]; then

  #### CREATE AND ATTACH AWS EBS VOLUMES
  ./modulescripts/create_and_attach_volumes.sh

  #### INSTALL PORTWORX
  ./modulescripts/setup_portworx_options.sh

  ./modulescripts/install_portworx.sh $PORTWORX_VERSION

  ./modulescripts/install_cli.sh portworx

  sleep 10

  ./modulescripts/check-status-with-name.sh portworx /infra/storage/portworx 600-900

  #### INSTALL PORTWORX-HADOOP
  ./modulescripts/install_px_hdfs.sh $PORTWORX_HDFS_VERSION

  ./modulescripts/install_cli.sh hdfs

  ./modulescripts/check-status-with-name.sh hdfs portworx-hadoop 300


fi

#### INSTALL EDGELB
./modulescripts/install_edgelb.sh $EDGE_LB_VERSION

./modulescripts/install_cli.sh edgelb

#### DEPLOY EDGELB CONFIG FOR KUBECTL
./modulescripts/kubectl_edgelb.sh


#### ADD LATEST MKE STUB UNIVERSE that supports dklb
#dcos package repo add --index=0 kubernetes-aws "$KUBERNETES_STUB_LINK"

#dcos package repo add --index=0 kubernetes-cluster-aws "$KUBERNETES_CLUSTER_STUB_LINK"


#### SETUP AND INSTALL MKE /kubernetes
./modulescripts/install_mke.sh $K8S_MKE_VERSION

./modulescripts/install_cli.sh kubernetes

#### SETUP SERVICE ACCOUNT FOR /PROD/KUBERNETES-PROD AND INSTALL K8S
./modulescripts/setup_prodk8s_SA.sh $K8S_PROD_VERSION

#### SETUP SERVICE ACCOUNT FOR /DEV/KUBERNETES-DEV AND INSTALL K8S
./modulescripts/setup_devk8s_SA.sh $K8S_DEV_VERSION

#### INSTALL CASSANDRA
if [ "$CASSANDRA_ENABLED" = "true" ]; then

  ./modulescripts/install_cassandra.sh $CASSANDRA_VERSION

  ./modulescripts/install_cli.sh cassandra

  sleep 10

  ./modulescripts/check-status-with-name.sh cassandra cassandra 150-200

fi

#### INSTALL KAFKA
./modulescripts/install_kafka.sh $KAFKA_VERSION

./modulescripts/install_cli.sh kafka

./modulescripts/check-status-with-name.sh kafka kafka 90-120

#### CREATE KAFKA TOPIC
dcos kafka topic create performancetest --partitions 10 --replication 3 --name=kafka

#### SETUP USER PROD-USER & GROUP PROD & SECRET /PROD/SECRET AND USER DEV-USER & GROUP DEV & SECRET /DEV/SECRET
./modulescripts/setup_RBAC.sh

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


#### REMOVE KEYS
rm -f private-key.pem 2> /dev/null
rm -f public-key.pem 2> /dev/null
rm -f edge-lb-private-key.pem 2> /dev/null
rm -f edge-lb-public-key.pem 2> /dev/null
rm -f private-infra-storage-portworx.pem 2> /dev/null
rm -f public-infra-storage-portworx.pem 2> /dev/null

#### INSTALL /DEV/JENKINS
./modulescripts/install_jenkins.sh $JENKINS_VERSION

./modulescripts/install_cli.sh jenkins

#### INSTALL /DEV/GITLAB-DEV
./modulescripts/install_gitlab.sh

#### INSTALL DCOS-MONITORING
./modulescripts/install_monitoring.sh $DCOS_MONITORING_VERSION

./modulescripts/install_cli.sh beta-dcos-monitoring

sleep 10

./modulescripts/check-status-with-name.sh beta-dcos-monitoring dcos-monitoring 90-120


#### INSTALL JUPYTERLABS
if [ "$JUPYTERLAB_ENABLED" = "true" ]; then

  ./modulescripts/install_jupyterlabs.sh $JUPYTERLAB_VERSION

fi

#### SETUP HOSTS FILE FOR mke-l7.ddns.net
echo may need your password to modify /etc/hosts
sudo ./modulescripts/append-etchosts.sh

#### OPEN WORKLOADS
./modulescripts/open_workloads.sh

#### OPEN PX-LIGHTHOUSE
if [ "$PORTWORX_ENABLED" = "true" ]; then

./modulescripts/open_pxlighthouse.sh

fi
