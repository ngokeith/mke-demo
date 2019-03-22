#!/bin/sh

if [[ $1 == "" ]]
then
        echo
        echo " An OS user was not specified. (i.e. core / centos) please retry"
        echo
        exit 1
fi

echo "Enabling mesos-agent metrics"
for i in $(dcos node |grep agent| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./mesos-agent.conf $1@$i:/tmp/mesos-agent.conf;
    ssh -o StrictHostKeyChecking=no $1@$i "sudo mv /tmp/mesos-agent.conf /var/lib/dcos/telegraf/telegraf.d/";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl restart dcos-telegraf";
    done

echo "Enabling mesos-master metrics"
for i in $(dcos node |grep master| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./mesos-master.conf $1@$i:/tmp/mesos-master.conf;
    ssh -o StrictHostKeyChecking=no $1@$i "sudo mv /tmp/mesos-master.conf /var/lib/dcos/telegraf/telegraf.d/";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl restart dcos-telegraf"
    done
