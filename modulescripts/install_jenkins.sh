#!/bin/bash

echo
echo "**** Installing Jenkins v$1 to /dev/jenkins"
echo
dcos package install jenkins --package-version=$1 --options=jenkins-options.json --yes
