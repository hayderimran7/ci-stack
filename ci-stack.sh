#!/bin/bash

if [ "${CI_STACK_DEVSTACK}" != "" ]
then
	./deploy devstack
	source bootstrap/devstack/env-admin.sh
fi

./deploy puppetdb
./deploy puppetmaster
