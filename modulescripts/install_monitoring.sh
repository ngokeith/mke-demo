#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " dcos-monitoring version was not entered. Aborting."
        echo
        exit 1
fi

# Add tunnel package for adding Mesos Metrics later
dcos package install tunnel-cli --cli --yes

# Install dcos-monitoring package
dcos package install beta-dcos-monitoring --options=monitoring-options.json --package-version=$1 --yes
sleep 15
