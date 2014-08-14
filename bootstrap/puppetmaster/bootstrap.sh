#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

sudo apt-get install -y git
sudo git clone https://git.openstack.org/openstack-infra/config /opt/config/production
sudo /opt/config/production/install_puppet.sh
sudo apt-get install -y hiera hiera-puppet
sudo /opt/config/production/install_modules.sh

# fix up the domain names in site.pp
DOMAIN=`hostname -d`
for f in `find /opt/config/production/modules /opt/config/production/manifests -type f`
do
	sudo sed -i $f -e "s/\\.openstack\\.org/.${DOMAIN}/gm"
done

# openstack requires ci-puppetmaster for the ca server, add it as a hostname here
sudo echo "127.0.2.1 ci-puppetmaster.${DOMAIN} ci-puppetmaster" | sudo tee -a /etc/hosts

# apply the puppet agent
sudo puppet agent --test --modulepath='/opt/config/production/modules:/etc/puppet/modules' 
