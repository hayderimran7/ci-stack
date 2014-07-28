#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y git
sudo git clone https://git.openstack.org/openstack-infra/config /opt/config/production
sudo /opt/config/production/install_puppet.sh
sudo apt-get install -y hiera hiera-puppet
sudo /opt/config/production/install_modules.sh
sudo puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' ${DIR}/puppetdb.pp
