export DKLB_PUBLIC_AGENT_IP=$(dcos task exec -it dcos-edgelb.pools.dklb curl ifconfig.co | tr -d '\r' | tr -d '\n')
echo Public IP of DKLB Edge-LB node is: $DKLB_PUBLIC_AGENT_IP
# NOTE, if that approach to finding the public IP doesn't work, consider https://github.com/ably77/dcos-se/tree/master/Kubernetes/mke/public_ip

#### SETUP HOSTS FILE FOR mke-l7.ddns.net

open http://$DKLB_PUBLIC_AGENT_IP:10001
sleep 1
open http://$DKLB_PUBLIC_AGENT_IP:10002
sleep 1
open http://$DKLB_PUBLIC_AGENT_IP:10003
sleep 1
open http://mke-l7.ddns.net:80
sleep 1
open http://mke-l7.ddns.net:81
sleep 1
open http://$DKLB_PUBLIC_AGENT_IP:10004
sleep 1
open http://$DKLB_PUBLIC_AGENT_IP:10005/docs/latest/
sleep 1
open http://mke-l7.ddns.net:82
