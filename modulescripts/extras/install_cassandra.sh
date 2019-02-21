#!/bin/bash

dcos package install cassandra --package-version=$1 --yes

echo To Upgrade, use the command:
echo
echo dcos cassandra update package-versions --name=cassandra
echo
echo and
echo
echo dcos cassandra update start --package-version="<PACKAGE_VERSION>" --name=cassandra
echo
