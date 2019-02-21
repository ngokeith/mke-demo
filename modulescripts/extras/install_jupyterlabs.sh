#!/bin/bash

echo
echo "**** Installing Jupyterlabs v$1"
echo
dcos package install jupyterlab-notebook --package-version=$1 --options=jupyter-options.json --yes
