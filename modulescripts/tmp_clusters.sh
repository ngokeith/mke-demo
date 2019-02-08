#!/bin/bash

#### MOVE DCOS CLI CLUSTERS TO /TMP/CLUSTERS

echo
echo "**** Moving DC/OS CLI configuration to /tmp/dcos-clusters"
echo "     So all existing DC/OS cluster configurations are now removed"
echo
sudo rm -rf /tmp/dcos-clusters 2> /dev/null
sudo mkdir /tmp/dcos-clusters
sudo mv ~/.dcos/clusters/* /tmp/dcos-clusters 2> /dev/null
sudo mv ~/.dcos/dcos.toml /tmp/dcos-clusters 2> /dev/null
sudo rm -rf ~/.dcos 2> /dev/null
