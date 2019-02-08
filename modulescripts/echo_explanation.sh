
echo "In the order below, this script will:"
echo
echo "1. Move existing DC/OS clusters into /tmp/dcos-clusters and set up a new cluster URL provided"
echo
echo "2. Update LICENSE_FILE if it exists in the optional variables section if it exists"
echo
echo "3. Do an ssh-add on the SSH_KEY_FILE in the optional variables section if it exists"
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
echo "13. Deploy Kafka producer deployment kafka-producer.yaml on /prod/kubernetes-prod that sends data to Kafka"
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
