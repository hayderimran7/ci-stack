#!/bin/bash

if [[ "${OS_USERNAME}" = ""  || "${OS_PASSWORD}" = "" ]]
then
	echo "Please set your OS_ environment variables."
	exit 1
fi

source common/functions.sh

# module to deply, key to use, remote user, IP of node to deploy from
MODULE=$1
KEY_NAME=${2:-"admin"}
USER=${3:-"ubuntu"}
DOMAIN=${4:-"novalocal"}

DEPLOYED=${DEPLOYED:-""}

if [ "${MODULE}" = "" ]
then
	echo "deploy.sh [module] [key_name] [user] [domain]"
	exit 0
fi

# Default OS auth details for devstack
OS_USERNAME=${OS_USERNAME:-"admin"}
OS_PASSWORD=${OS_PASSWORD:-"supersecret"}
OS_TENANT_NAME=${OS_TENANT_NAME:-"admin"}
OS_AUTH_URL=${OS_AUTH_URL:-"http://127.0.0.1:35357/v2.0"}

# Using a different deployment branch? Set up the env here
CI_STACK=${CI_STACK:-"https://github.com/jedimike/ci-stack.git"}
CI_STACK_BRANCH=${CI_STACK_BRANCH:-"master"}

provision_node ${MODULE} ${KEY_NAME} ${USER}

if [ "${MODULE}" != "devstack" ]
then
	upload_bootstrap ${MODULE} ${KEY_NAME} ${USER}

	DEPLOYED="${DEPLOYED} ${MODULE}"
	MODULE_IP=`heat output-show ${MODULE} instance_ip|sed -e 's/"//g'`

	# update all the nodes with the new node's ip
	for node in ${DEPLOYED}
	do
		TARGET_IP=`heat output-show ${node} instance_ip|sed -e 's/"//g'`
		ssh -o StrictHostKeyChecking=no -i keys/${KEY_NAME}_key ${USER}@${TARGET_IP} "source common/functions.sh && add_hosts_entry ${MODULE} ${DOMAIN} ${MODULE_IP}"
	done


	for HOOK_SCRIPT in `find bootstrap -name post_${MODULE}.sh`
	do
		# If a module has a script that needs to be run after this
		# module, run it now. This is mostly because puppetdb
		# needs to be set up before the puppetmaster, and afterwards
		# it needs to get config from the puppetmaster.
		run_post ${HOOK_SCRIPT} ${KEY_NAME} ${USER}
	done

	export DEPLOYED
fi

run_bootstrap ${MODULE} ${KEY_NAME} ${USER}
