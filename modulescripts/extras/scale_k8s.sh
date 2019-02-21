#!/bin/bash

dcos kubernetes cluster update --cluster-name=prod/kubernetes-prod --options=kubernetes-prod-scale-options.json
