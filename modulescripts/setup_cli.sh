#!/bin/bash

echo
echo "**** Running command: dcos cluster setup"
#echo
dcos cluster setup $1 --insecure --username=$2 --password=$3
echo
echo "**** Installing enterprise CLI"
echo
dcos package install dcos-enterprise-cli --yes
echo
echo "**** Setting core.ssl_verify to false"
echo
dcos config set core.ssl_verify false
