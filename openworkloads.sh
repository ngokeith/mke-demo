#### Opening dklb-pool-1 workloads
# This is a real hack, and it might not work correctly!
echo
echo "**** Setting env var DKLB_PUBLIC_AGENT_IP using a hack of a method"
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
echo "     hello-world1 service - port 80"
echo "     hello-world2 service - port 8080"
echo "     hello-world3 service - port 8181"
echo "     dcos-site1 service - port 10004"
echo "     dcos-site2 service - port 10005"

open "http://$DKLB_PUBLIC_AGENT_IP"
