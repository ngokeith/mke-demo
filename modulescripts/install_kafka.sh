#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kafka version was not entered. (i.e. 2.3.0-1.1.0) Aborting."
        echo
        exit 1
fi

if [[ $2 == "" ]]
then
        echo
        echo " Kafka options path not entered. (i.e. kafka-options.json) Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing kafka v$1 using options json $2"
echo
dcos package install kafka --package-version=$1 --options=$2 --yes
