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
