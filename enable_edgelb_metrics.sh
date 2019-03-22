#!/bin/sh

if [[ $1 == "" ]]
then
        echo
        echo " An OS user was not specified. (i.e. core / centos) please retry"
        echo
        exit 1
fi

echo "Enabling public mesos-agent edgelb metrics"
for i in $(dcos node |grep agent| awk '{ print $2 }')
    do
    scp -o StrictHostKeyChecking=no ./haproxy_exporter.tar.gz $1@$i:/tmp/haproxy_exporter.tar.gz;
    scp -o StrictHostKeyChecking=no ./haproxy-exporter.service $1@$i:/tmp/haproxy-exporter.service;
    ssh -o StrictHostKeyChecking=no $1@$i "sudo tar xvf /tmp/haproxy_exporter.tar.gz";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo cp ./haproxy_exporter-*/haproxy_exporter /usr/bin/";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo mv /tmp/haproxy-exporter.service /etc/systemd/system/";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl daemon-reload";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl enable haproxy-exporter";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl restart haproxy-exporter";

    sed "s/DCOS_NODE_PRIVATE_IP/$i/g" haproxy-exporter.conf.template > haproxy-exporter.conf
    scp -o StrictHostKeyChecking=no ./haproxy-exporter.conf $1@$i:/tmp/haproxy-exporter.conf;
    ssh -o StrictHostKeyChecking=no $1@$i "sudo mv /tmp/haproxy-exporter.conf /var/lib/dcos/telegraf/telegraf.d/haproxy-exporter.conf";
    ssh -o StrictHostKeyChecking=no $1@$i "sudo systemctl restart dcos-telegraf";

    done
