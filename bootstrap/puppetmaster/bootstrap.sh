#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y git
sudo git clone https://git.openstack.org/openstack-infra/config /opt/config/production
sudo /opt/config/production/install_puppet.sh
sudo apt-get install -y hiera hiera-puppet
sudo /opt/config/production/install_modules.sh

# fix up the domain names in site.pp
DOMAIN=`hostname -d`
sudo sed -i /opt/config/production/manifests/site.pp -e 's/\.openstack\.org/${DOMAIN}/gm'

# apply the puppet agent
sudo puppet apply --modulepath='/opt/config/production/modules:/etc/puppet/modules' -e 'include openstack_project::puppetmaster'