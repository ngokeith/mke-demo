#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Kafka version was not entered. Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing kafka v$1"
echo
dcos package install kafka --package-version=$1 --options=options-kafka.json --yes
