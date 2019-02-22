#!/bin/bash

if [[ $1 == "" ]]
then
        echo
        echo " Jupyterlab version was not entered. (i.e. 1.2.0-0.33.7) Aborting."
        echo
        exit 1
fi

echo
echo "**** Installing Jupyterlabs v$1"
echo
dcos package install jupyterlab --package-version=$1 --options=options-jupyter.json --yes
