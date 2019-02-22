#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Jenkins version was not entered. Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing Jenkins v$1 to /dev/jenkins"
echo
dcos package install jenkins --package-version=$1 --options=jenkins-options.json --yes
