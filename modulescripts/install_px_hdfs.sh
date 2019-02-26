#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " HDFS version was not entered. (i.e. 1.2-2.6.0) Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing PX-HDFS v$1"
echo
dcos package install portworx-hadoop --package-version=$1 --yes
