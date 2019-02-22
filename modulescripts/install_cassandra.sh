#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Cassandra version was not entered. (i.e. 2.3.0-3.0.16) Aborting."
        echo
        exit 1
fi

echo "**** Installing Cassandra v$1"
echo
dcos package install cassandra --package-version=$1 --yes
echo
echo To Upgrade, use the command:
echo
echo dcos cassandra update package-versions --name=cassandra
echo
echo and
echo
echo dcos cassandra update start --package-version="<PACKAGE_VERSION>" --name=cassandra
echo
