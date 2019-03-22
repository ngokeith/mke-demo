#!/bin/sh

if [[ $1 == "" ]]
then
        echo
        echo " An OS user was not specified. (i.e. core / centos) please retry"
        echo
        exit 1
fi

sudo dcos tunnel vpn --user=$1
