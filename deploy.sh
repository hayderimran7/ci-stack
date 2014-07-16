#!/bin/bash

source common/functions.sh

MODULE=$1
KEY=${2:-"keys/admin_key"}
USER=${3:-"ubuntu"}
DEPLOYMENT_NODE_IP=${4:-""}
OS_USERNAME=${OS_USERNAME:-"admin"}
OS_PASSWORD=${OS_PASSWORD:-"supersecret"}
OS_TENANT_NAME=${OS_TENANT_NAME:-"admin"}
OS_AUTH_URL=${OS_AUTH_URL:-"http://127.0.0.1:35357/v2.0"}

provision_node
wait_for_ssh
upload_cistack
run bootstrap
