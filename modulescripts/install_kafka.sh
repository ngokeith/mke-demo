#!/bin/bash

echo
echo "**** Installing kafka v$1"
echo
dcos package install kafka --package-version=$1 --options=options-kafka.json --yes
