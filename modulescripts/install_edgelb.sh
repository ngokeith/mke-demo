#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Edgelb version was not entered. (i.e. 1.3.0) Aborting."
        echo
        exit 1
fi

#### INSTALL EDGE-LB

echo
echo "**** Installing Edge-LB v$1"
echo

#### ADD EDGELB STABLE REPO
dcos package repo add --index=0 edge-lb https://downloads.mesosphere.com/edgelb/v$1/assets/stub-universe-edgelb.json
dcos package repo add --index=0 edge-lbpool https://downloads.mesosphere.com/edgelb-pool/v$1/assets/stub-universe-edgelb-pool.json

#### CREATE KEYS, SECRETS, AND ASSIGN EDGELB PERMISSIONS
dcos security org service-accounts keypair edge-lb-private-key.pem edge-lb-public-key.pem
dcos security org service-accounts create -p edge-lb-public-key.pem -d "Edge-LB service account" edge-lb-principal
# dcos security org service-accounts show edge-lb-principal
# TODO DEBUG Getting error on next line, says it already exists, assuming it was added for a strict mode cluster?
dcos security secrets create-sa-secret --strict edge-lb-private-key.pem edge-lb-principal dcos-edgelb/edge-lb-secret
# TODO DEBUG Getting error on next line, says already part of group
dcos security org groups add_user superusers edge-lb-principal

# TODO: later add --package-version, it doesn't work at the moment
dcos package install --options=edgelb-options.json edgelb --yes
# Is redundant but harmless
dcos package install edgelb --cli --yes

#### WAIT FOR EDGE-LB TO INSTALL

# This is done now so the next section that needs user input to get the sudo password can happen
# sooner rather than later, so you can walk away and let the script run after
echo
echo "**** Waiting for Edge-LB to install"
echo
sleep 20
echo "     Ignore any 404 errors on next line that begin with  dcos-edgelb: error: Get https://"
until dcos edgelb ping; do sleep 3 & echo "still waiting..."; done
