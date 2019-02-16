#!/bin/bash

if [[ -e $1 ]]; then
    echo
    echo "**** Adding SSH key $1 to this workstation's SSH keychain"
    echo
    ssh-add $1
else
    echo
    echo "**** SSH key $1 not found, no key will be added to this workstation's SSH keychain"
    echo
fi
