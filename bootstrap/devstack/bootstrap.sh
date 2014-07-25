#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install git
rm -rf devstack
git clone https://github.com/openstack-dev/devstack.git
cp ${DIR}/devstack-local.conf devstack/local.conf
cp ${DIR}/devstack-local.sh devstack/local.sh
cd devstack
./stack.sh
