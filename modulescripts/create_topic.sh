#!/bin/bash

dcos kafka topic create performancetest --partitions 5 --replication 3 --name=$1
