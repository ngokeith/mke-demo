
#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kubernetes service ID not entered. (i.e. prod/kubernetes-prod) Aborting."
        echo
        exit 1
fi

echo
echo "**** Testing if K8s install of $1 is done,"
echo
# Sometimes I open another shell while waiting, since this is the biggest delay,
# so let's fix the dcos cli and kubectl now (and at the end of the script)
seconds=0
OUTPUT=1
while [ "$OUTPUT" != 0 ]; do
  # since the kube-node-2 kubelet is the last to deploy, we will monitor it
  OUTPUT=`dcos kubernetes cluster debug plan status deploy --cluster-name=$1 | grep deploy | awk '{print $4}'`;
  if [ "$OUTPUT" = "(COMPLETE)" ];then
        OUTPUT=0
  fi
  seconds=$((seconds+10))
  printf "Waited $seconds seconds for Kubernetes to start. Still waiting. This will usually take ~360-400 seconds\n"
  sleep 10
done

echo
echo "**** $1 install complete"
