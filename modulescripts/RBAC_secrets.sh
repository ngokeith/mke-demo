#!/bin/bash

#### SETUP USER PROD-USER & GROUP PROD & SECRET /PROD/SECRET

echo
echo
echo "**** Creating DC/OS user prod-user, group prod, secret /prod/example-secret, and example app"
echo
dcos security org users create prod-user --password=deleteme
dcos security org groups create prod
dcos security org groups add_user prod prod-user
dcos security secrets create /prod/example-secret --value="prod-team-secret"
dcos security org groups grant prod dcos:secrets:list:default:/prod full
dcos security org groups grant prod dcos:secrets:default:/prod/* full
dcos security org groups grant prod dcos:service:marathon:marathon:services:/prod full
dcos security org groups grant prod dcos:adminrouter:service:marathon full
# Appears to be necessary per COPS-2534
dcos security org groups grant prod dcos:secrets:list:default:/ read

#### SETUP USER DEV-USER & GROUP DEV & SECRET /DEV/SECRET

echo
echo "**** Creating DC/OS user dev-user, group dev, secret /dev/example-secret, and example app"
echo
dcos security org users create dev-user --password=deleteme
dcos security org groups create dev
dcos security org groups add_user dev dev-user
dcos security secrets create /dev/example-secret --value="dev-team-secret"
dcos security org groups grant dev dcos:secrets:list:default:/dev full
dcos security org groups grant dev dcos:secrets:default:/dev/* full
dcos security org groups grant dev dcos:service:marathon:marathon:services:/dev full
dcos security org groups grant dev dcos:adminrouter:service:marathon full
# Appears to be necessary per COPS-2534
dcos security org groups grant dev dcos:secrets:list:default:/ read
