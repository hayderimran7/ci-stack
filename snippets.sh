#!/bin/bash

set -xe

CI_CONFIG_BRANCH=${CI_CONFIG_BRANCH:-""}
CI_WORKSPACE=${CI_WORKSPACE:-~/ci-workspace}
CI_INITIAL_CLOUD_SETUP=${CI_INITIAL_CLOUD_SETUP:-"False"}

# Admin credentials needed here

# Command aliases
ADMIN_SSH="ssh -o StrictHostKeyChecking=no -i ${CI_WORKSPACE}/keys/admin_key"

if [ "${CI_INITIAL_CLOUD_SETUP}" == "True" ]; then
	# Reset the workspace
	mkdir ${CI_WORKSPACE}
	cd ${CI_WORKSPACE}

	# Init a git repository to manage
	mkdir repo
	git init repo

	# Init keys for node access
	mkdir keys
	ssh-keygen -f keys/admin_key -q -N ""
	nova keypair-add --pub-key keys/admin_key.pub admin

	# Set up an ubuntu image in glance to run things on
	glance image-create --name precise-server-cloudimg-amd64 --disk-format qcow2 --container-format bare --is-public true --location http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img

	# create a little flavor for small boxes with low ram but slightly bigger disks
	nova flavor-create m1.little 37 512 5 1
fi

# spawn puppetdb
nova boot --flavor m1.little --image precise-server-cloudimg-amd64 --key-name admin puppetdb

# Bootstrap puppetdb
while [ -z "${PUPPETDB_IP}" ]; do
    PUPPETDB_IP=`nova list|grep puppetdb|grep private|sed -e 's/.*private=\([0-9.]\+\).*/\1/'`
done

ssh-keygen -f ~/.ssh/known_hosts -R $PUPPETDB_IP 

if ! timeout 360 sh -c "while ! ${ADMIN_SSH} ubuntu@${PUPPETDB_IP} echo success; do sleep 18; done"; then
    echo "server didn't become ssh-able!"
    exit 1
fi

# Make a bootstrap manifest for the puppetdb
following as root
    1  git clone https://git.openstack.org/openstack-infra/config /opt/config/production
    2  apt-get install git
    3  /opt/config/production/install_puppet.sh
    4  git clone https://git.openstack.org/openstack-infra/config /opt/config/production
    5  /opt/config/production/install_puppet.sh
    6  sudo apt-get install hiera hiera-puppet
    7  histor
    8  history

# Copy hiera data into place

exit 0


# Set up puppetmaster
nova boot --flavor m1.small --image precise-server-cloudimg-amd64 --key-name admin puppetmaster

while [ -z "${PUPPETMASTER_IP}" ]; do
    PUPPETMASTER_IP=`nova list|grep puppetmaster|grep private|sed -e 's/.*private=\([0-9.]\+\).*/\1/'`
done

ssh-keygen -f ~/.ssh/known_hosts -R $PUPPETMASTER_IP 

if ! timeout 360 sh -c "while ! ${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} echo success; do sleep 18; done"; then
    echo "server didn't become ssh-able!"
    exit 1
fi

${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo apt-get install -y git
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo git clone https://github.com/jedimike/ci-stack-config /opt/config/production
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo /opt/config/production/install_puppet.sh
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo apt-get install -y puppetmaster-passenger hiera hiera-puppet
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo bash /opt/config/production/install_modules.sh

# All our hiera config is public as this isn't a production system, totally throwaway like a devstack install
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo git clone https://github.com/jedimike/ci-stack-hiera-config
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo cp -a ci-stack-hiera-config/etc /
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo cp -a ci-stack-hiera-config/var /

# Apply the puppet configuration to give a fully functional puppetmaster
${ADMIN_SSH} ubuntu@${PUPPETMASTER_IP} sudo	puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'

# Now we have our puppetmaster, time to spin up X Y Z
