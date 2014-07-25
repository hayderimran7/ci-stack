#!/bin/bash

sudo apt-get install -y git
sudo git clone https://git.openstack.org/openstack-infra/config /opt/config/production
sudo /opt/config/production/install_puppet.sh
sudo apt-get install -y hiera hiera-puppet
sudo /opt/config/production/install_modules.sh

