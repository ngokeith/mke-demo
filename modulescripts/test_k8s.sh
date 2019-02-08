
echo
echo "**** Testing if K8s install of /prod/kubernetes-prod is done,"
echo
# Sometimes I open another shell while waiting, since this is the biggest delay,
# so let's fix the dcos cli and kubectl now (and at the end of the script)
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the kube-node-2 kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=prod/kubernetes-prod | grep kube-node-1 | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kubernetes to start. Still waiting. This will usually take ~360-400 seconds\n"
  sleep 10
done

echo
echo "**** /prod/kubernetes-prod install complete"


echo
echo "**** Making sure the /dev/kubernetes-dev install is complete"
echo
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for dev Kubernetes to start. Still waiting.\n"
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=dev/kubernetes-dev | grep kube-node-0 | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  sleep 10
done
echo
echo "**** /dev/kubernetes-dev install complete"
echo
