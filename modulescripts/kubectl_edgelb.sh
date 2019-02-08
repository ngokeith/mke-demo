#!/bin/bash

echo
echo "**** Deploying Edge-LB config from edgelb-kubectl-two-clusters.json"
echo
dcos edgelb create edgelb-kubectl-two-clusters.json
echo
echo "**** Sleeping for 30 seconds since it takes some time for Edge-LB's config to load"
echo
sleep 30
echo
echo "**** Running dcos 'edgelb status edgelb-kubectl-two-clusters'"
echo
dcos edgelb status edgelb-kubectl-two-clusters
#echo
#echo "**** Running 'dcos edgelb show edgelb-kubectl-two-clusters'"
#echo
#dcos edgelb show edgelb-kubectl-two-clusters
