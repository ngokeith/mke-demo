#!/bin/bash

if [[ -e $1 ]]; then
    echo
    echo "**** Updating DC/OS license using $1"
    echo
    dcos license renew $1
else
    echo
    echo "**** License file $1 not found, license will not be updated"
    echo
fi
