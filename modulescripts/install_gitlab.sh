#!/bin/bash

echo
echo "**** Deploy Gitlab /dev/gitlab-dev"
dcos marathon app add gitlab-dev.json
