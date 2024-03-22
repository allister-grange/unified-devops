#!/bin/bash

# all of this needs to be moved to ansible
groupadd -g 1001 grangeal 
useradd grangeal -n -g 1001 -u 1001
apt-get update
apt-get -o DPkg::Lock::Timeout=-1 install nginx -y
systemctl enable nginx
