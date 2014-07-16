#!/bin/bash

WORKSPACE=${WORKSPACE:-"~/workspace"}

mkdir -p $WORKSPACE
cd $WORKSPACE

# Init keys for node access
mkdir keys
ssh-keygen -f keys/admin_key -q -N ""
nova keypair-add --pub-key keys/admin_key.pub admin

# Set up an ubuntu image in glance to run things on
glance image-create --name precise-server-cloudimg-amd64 --disk-format qcow2 --container-format bare --is-public true --location http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img

# create a little flavor for small boxes with low ram but slightly bigger disks
nova flavor-create m1.little 37 512 5 1
