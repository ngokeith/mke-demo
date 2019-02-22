#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " HDFS version was not entered. (i.e. 2.5.0-2.6.0-cdh5.11.0) Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing HDFS v$1"
echo
dcos package install hdfs --package-version=$1 --yes
