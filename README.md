# SETUP SCRIPT FOR TWO K8S CLUSTERS ON DC/OS ("2k8s")
Revision 1-30-19

This is a script for Enterprise DC/OS 1.12 that will setup two Kubernetes clusters  
This script has only been tested on OSX with DC/OS >1.12.0 Enterprise Edition  

In the order below, this script will:

1. Move existing DC/OS clusters into /tmp/dcos-clusters and set up a new cluster URL provided

2. Update $LICENSE_FILE if it exists in the optional variables section if it exists

3. Do an ssh-add on the $SSH_KEY_FILE in the optional variables section if it exists

4. Move existing kube config to /tmp/kubectl-config so we can set up a new kube config

5. Add repo and install Edge-LB - deploy kubectl pool once completed

6. Set up Service Accounts and Install MKE Kubernetes engine

7. Set up Service Accounts and Install /prod/kubernetes-prod cluster
- HA Deployment (3x etcd / 3x control-plane), 2 private nodes, RBAC enabled, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1     

8. Set up Service Accounts and Install /dev/kubernetes-dev cluster
- Non-HA deployment, 1 private node, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1  

9. Install Jenkins in /dev/jenkins

10. Install Kafka - Create a topic called performancetest

11. Wait for Kubernetes to complete deployment and connect clusters /dev/kubernetes-dev and /prod/kubernetes-prod using kubectl

12. Deploy Kafka producer deployment `kafka-producer.yaml` on /prod/kubernetes-prod that sends data to Kafka

13. Install DKLB (beta) for L4/L7 Ingress on MKE

14. Multiple Hello World services, and multiple DC/OS Websites exposed on L4 and L7 through Edge-LB

15. Create a prod-user in the prod group and a dev-user in the dev group both with the default DC/OS password

16. Install dcos-monitoring and open up Grafana dashboard

17. Open up L4 services in your browser

## PREREQUISITES

1. The DC/OS CLI and kubectl must already be installed on your local machine

2. Ensure that ports 6443 and 6444 are not blocked by firewall rules

## SETUP

1. Clone this repo  
   `git clone https://github.com/ably77/mke-demo.git`  
   `cd mke-demo`

2. Optional: Modify the variables section in the `runme.sh`

Default variables below:
```
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
```

#### USAGE

1. Start a cluster, such as in CCM or TF. Minimum of 9 private agents (m4.xlarge) or 5 private agents (m4.2xlarge), only 1 public agent, DC/OS EE 1.12

2. Ensure that Port 6443/6444 are at minimum open to your local machine (optional 81,82,10000-10005 as well if you want to see the Kubernetes exposed services in your browser)

3. Copy the master's URL to your clipboard. If it begins with HTTP the script will change it to HTTPS.

4. Modify the Variables section in the runme.sh

5. `./runme <MASTER_URL>`

6. Wait for it to finish (~ 9-12 min)
