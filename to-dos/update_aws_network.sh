## Determine all Security Group Name/ID by tags
aws ec2 describe-security-groups --filters Name=tag:Name,Values=aly-hybrid --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}"

## Determine Security Group Name/ID by value group-name
aws ec2 describe-security-groups --filters Name=group-name,Values=dcos-aly-hybrid-public-agents-lb-firewall Name=tag:Name,Values=aly-hybrid --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}"


## ELB Listener on 6443
REGION=us-west-2
LBNAME=ext-aly-hybrid
GROUP_ID=sg-001c5dbfec6b7e05a

aws --region=$REGION elb create-load-balancer-listeners --load-balancer-name=$LBNAME --listeners Protocol=TCP,LoadBalancerPort=6443,InstanceProtocol=TCP,InstancePort=6443

## Open Ports X-Y for $GROUP_ID
aws --region=us-west-2 ec2 authorize-security-group-ingress --group-id=$GROUP_ID --protocol=tcp --port=6443-6444 --cidr=0.0.0.0/0
aws --region=us-west-2 ec2 authorize-security-group-ingress --group-id=$GROUP_ID --protocol=tcp --port=10001-10100 --cidr=0.0.0.0/0
