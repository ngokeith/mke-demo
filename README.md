# Setup Script for Two K8s Clusters on DC/OS ("2k8s")
Revision 3-7-19

This is a script for Enterprise DC/OS 1.12 that will setup two Kubernetes clusters with L4/L7 Ingress, Gitlab, Jenkins, a Prometheus/Grafana monitoring stack, and a Kafka monitoring demonstration  

This script has only been tested on OSX with DC/OS >1.12.0 Enterprise Edition  

In the order below, this script will:

1. Move existing DC/OS clusters into /tmp/dcos-clusters and set up a new cluster URL provided

2. Update $LICENSE_FILE if it exists in the optional variables section if it exists

3. Do an ssh-add on the $SSH_KEY_FILE in the optional variables section if it exists

4. Move existing kube config to /tmp/kubectl-config so we can set up a new kube config

5. Create additional EBS volumes and Install Portworx if Optional Variable is set to "true"

6. Add repo and install Edge-LB - deploy kubectl pool once completed

7. Set up Service Accounts and Install MKE Kubernetes engine

8. Set up Service Accounts and Install /prod/kubernetes-prod cluster
- HA Deployment (3x etcd / 3x control-plane), 2 private nodes, RBAC enabled, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1     

9. Set up Service Accounts and Install /dev/kubernetes-dev cluster
- Non-HA deployment, 1 private node, control plane CPU lowered to 0.5, private reserved resources kube cpus lowered to 1  

10. Install HDFS if Optional Variable is set to "true"

11. Install Jenkins in /dev/jenkins

12. Install Gitlab in /dev/gitlab-dev, expose gitlab-dev on your EDGELB_PUBLIC_AGENT_IP:10006

13. Install Jupyterlabs Notebook if Optional Variable is set to "true"

14. Install Kafka - Create a topic called performancetest

15. Set up RBAC users and groups (prod/prod-user, dev/dev-user, infra/infra-user)

16. Wait for Kubernetes to complete deployment and connect clusters /dev/kubernetes-dev and /prod/kubernetes-prod using kubectl

17. Deploy Kafka producer deployment `kafka-producer.yaml` on /prod/kubernetes-prod that sends data to Kafka

18. Install DKLB for L4/L7 Ingress on MKE

19. Multiple Hello World services, and multiple DC/OS Websites exposed on L4 and L7 through Edge-LB

20. Install dcos-monitoring and open up Grafana dashboard

21. Install Cassandra if Optional Variable is set to "true"

22. Open up Gitlab, Jupyterlab, L4 and L7 services in your browser

23. Open the Portworx Lighthouse UI if Optional Variable is set to "true"

## PREREQUISITES

1. The DC/OS CLI and kubectl must already be installed on your local machine

You can install the DC/OS CLI for Mac OSX below:
```
[ -d /usr/local/bin ] || sudo mkdir -p /usr/local/bin &&
curl https://downloads.dcos.io/binaries/cli/darwin/x86-64/dcos-1.12/dcos -o dcos &&
sudo mv dcos /usr/local/bin &&
sudo chmod +x /usr/local/bin/dcos
```

2. Ensure that ports 6443 and 6444 are not blocked by firewall rules (optional 81,82,10000-10005 as well if you want to see the Kubernetes exposed services in your browser)

## SETUP

1. Clone this repo  
   `git clone https://github.com/ably77/mke-demo.git`  
   `cd mke-demo`

2. Optional: Modify the variables section in the `runme.sh`

#### USAGE

1. Start a cluster, such as in CCM or TF. Minimum of 9 private agents (m4.xlarge) or 4 private agents (m4.2xlarge), only 1 public agent, DC/OS EE 1.12

2. Ensure that Port 6443/6444 are at minimum open to your local machine (optional 81,82,10000-10005 as well if you want to see the Kubernetes exposed services in your browser)

3. Copy the master's URL to your clipboard. If it begins with HTTP the script will change it to HTTPS.

4. Modify the Variables section in the runme.sh

5. `sudo ./runme <MASTER_URL>`

6. Wait for it to finish (~ 10-12 min)

## EXTENDING THIS DEMO

#### OPTIONAL Variables

Optional variables in `runme.sh`:

If you set the extra add-ons below to `true`, make sure you have enough resources in your cluster to complete the demo:
- If all all features are set to `true` you will need a total of at least 49.3 CPU shares
  - 7x 8-core Private agents
  - 1x 4-core Public Agent
- Portworx Installation for 7 Private Agent nodes can take up to 10-15 additional minutes
- HDFS requires minimum 6 private agent nodes in your cluster

```
######## OPTIONAL VARIABLES ########
PORTWORX_ENABLED="false"
JUPYTERLAB_ENABLED="false"
HDFS_ENABLED="false"
CASSANDRA_ENABLED="false"

# OPTIONAL PACKAGE VERSIONS
PORTWORX_VERSION="1.3.3-1.6.1.1"
CASSANDRA_VERSION="2.3.0-3.0.16"
HDFS_VERSION="2.5.0-2.6.0-cdh5.11.0"
PORTWORX_HDFS_VERSION="1.2-2.6.0"
JUPYTERLAB_VERSION="1.2.0-0.33.7"
```

#### Upgrading a Framework service

To upgrade a Framework service run the script below:
```
./modulescripts/upgrade_service.sh
```

The script will prompt you for the Framework Name and Service Name, and then will display the available upgrade/downgrade versions

Output should look similar to below:
```
$ ./modulescripts/upgrade_service.sh
Input Framework Name (i.e. cassandra  kafka  elastic  kubernetes): kafka
Input Service Name (i.e. /dataservices/cassandra /dataservices/kafka  prod/kubernetes-prod dev/kubernetes-dev): kafka
Current package version is: "2.3.0-1.0.0"
Package can be downgraded to: ["2.2.0-1.0.0"]
Package can be upgraded to: ["2.3.0-1.1.0"]
Input package version to upgrade/downgrade to: 2.2.0-1.0.0
```

If you have the `watch` command installed on your local machine you can use the following script to watch your service upgrade:
```
./modulescripts/watch_upgrade.sh
```

#### Scaling a Framework Service

To scale a Framework service run the script below:
```
./modulescripts/scale_service.sh
```

The script will prompt you for the Framework Name, Service Name, and options.json path and initiate an upgrade

An example output should look similar to below:
```
$ ./modulescripts/scale_service.sh
Input Framework Name (i.e. cassandra  kafka  elastic  kubernetes): kafka
Input Service Name (i.e. /dataservices/cassandra /dataservices/kafka  prod/kubernetes-prod dev/kubernetes-dev): kafka
Input optionsjson name (i.e. options-kafka.json): options-kafka.json
Update started. Please use `dcos kafka --name=kafka update status` to view progress.
```

If you have the `watch` command installed on your local machine you can use the following script to watch your service upgrade:
```
./modulescripts/watch_upgrade.sh
```

#### Set Up and Demo Portworx PersistentVolumeClaim

If portworx is installed on your cluster you can demo kubernetes consuming a portworx enabled PVC.

First set up your kubernetes PVC. If you take a look at the script, this is what it does:
- Set the context to kubernetes-prod
- Install Portworx Stork for kubernetes
- Creates a kubernetes StorageClass for Portworx
- Define StorageClass as the default Storage Class in your kubernetes cluster
- Create the kubernetes Portworx PersistentVolumeClaim
- Check status of the PVC

```
./modulescripts/extras/setup_px_k8s_pvc.sh
```

Run the script below to demo storage persistence using the PVC that was just set up. The demo will prompt you and walk you through the commands to create the `pvc-pod.yaml` which uses the portworx volume that we just created, load data, destroy the pod, and demonstrate data persistence by creating a second pod that uses the same volume.
```
./modulescripts/extras/demo_px_k8s_pvc.sh
```

#### Demonstrate Region Aware Deployment of Kubernetes

If you have multiple regions in your DC/OS cluster, you can demonstrate a region aware deployment of a kubernetes cluster. For this demo we will build a cluster called uat/kubernetes-uat

Run the script below and follow the instructions to designate your kubernetes cluster region. This script will:
- Set up the uat/kubernetes-uat kubernetes service account, secrets, and permissions if they don't exist already
- Allow you to select a region for your deployment (i.e. us-west-2 or us-east-1)
- Allow you to select your kubernetes version for the uat/kubernetes-uat deployment
- Deploy your uat/kubernetes-uat cluster

```
./modulescripts/extras/regionaware/setup_regionaware_k8suat.sh
```
