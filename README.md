### SETUP SCRIPT FOR TWO K8S CLUSTERS ON DC/OS ("2k8s")
Revision 1-25-19

This is a script for Enterprise DC/OS 1.12 that will setup two Kubernetes clusters  
This script has only been tested on OSX with DC/OS 1.12.1 Enterprise Edition  

This script will:

1. Install Edge-LB with a configuration to enable proxying kubectl to the two K8s clusters

2. Install Mesosphere Kubernetes Engine (MKE)

3. Install a K8s cluster named /prod/kubernetes-prod  
   1 private node, RBAC enabled, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1     

4. Install a K8s cluster named /dev/kubernetes-dev   
   1 private node, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1  

5. Install a DC/OS license, if it exists

6. Install an SSH key to the workstation via ssh-add, if it exists

7. Your existing kubectl config file will be moved to /tmp/kubectl-config, so any existing kubectl configs will be removed

8. Your existing DC/OS cluster configs will be moved to /tmp/clusters because of a bug (that might be fixed) when too many clusters are defined, so any existing DC/OS cluster configs will be removed

9. Deploy the latest DKLB bits for L4/L7 loadbalancing

10. Deploy several example web services and expose through L4/L7

11. A Jenkins deployment named /dev/jenkins"

#### PREREQUISITES

1. The DC/OS CLI and kubectl must already be installed on your local machine

2. Ensure that ports 6443 and 6444 are not blocked by firewall rules

#### SETUP

1. Clone this repo  
   `git clone https://github.com/ably77/mke-demo.git`  
   `cd mke-demo`

2. Optional: Modify the variables section in the `runme.sh`

Default variables below:
```
######## VARIABLES ########

SCRIPT_VERSION="JAN-30-2019"
LICENSE_FILE="dcos-1-12-license-50-nodes.txt"
JENKINS_VERSION="3.5.2-2.107.2"
#KEEP FOR OLD STABLE - EDGE_LB_VERSION="1.2.3-42-g6643742"
K8S_MKE_VERSION="stub-universe"
K8S_PROD_VERSION="stub-universe"
K8S_DEV_VERSION="stub-universe"
SSH_KEY_FILE="/Users/josh/ccm-priv.key"
DCOS_USER="bootstrapuser"
DCOS_PASSWORD="deleteme"

# BELOW IS EDGELB VARS FOR BETA TESTING DKLB
EDGE_LB_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb/stub-universe-edgelb.json"
EDGE_LB_POOL_LINK="https://edge-lb-infinity-artifacts.s3.amazonaws.com/autodelete7d/v1.2.3-111-gc28ece3/edgelb-pool/stub-universe-edgelb-pool.json"
# BELOW IS MKE VARS FOR BETA TESTING DKLB
KUBERNETES_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes/master/stub-universe-kubernetes.json"
KUBERNETES_CLUSTER_STUB_LINK="https://universe-converter.mesosphere.com/transform?url=https://dcos-kubernetes-artifacts.s3.amazonaws.com/nightlies/kubernetes-cluster/master/stub-universe-kubernetes-cluster.json"
# VHOST Routing Hostname for L7 Loadbalancing
VHOST="mke-l7.ddns.net"
```

#### USAGE

1. Start a cluster, such as in CCM or TF. Minimum of 7 private agents (m4.xlarge), only 1 public agent, DC/OS EE 1.12

2. Copy the master's URL to your clipboard. If it begins with HTTP the script will change it to HTTPS.

3. `sudo ./runme <MASTER_URL>`

4. Wait for it to finish (~ 7 min)
