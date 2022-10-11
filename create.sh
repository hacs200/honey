#!/bin/bash

# $1 = container-name
# $2 = external ip address
# $3 = external network netmask prefix

if [ $# -ne 3 ]
then
	echo "Usage: ./create.sh [container name] [external ip address] [external network netmask prefix]"
	exit 1
fi

# CREATE CONTAINER
sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n $1 -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n $1

# CREATE FAKE ADMIN USER
sudo lxc-attach -n $1 -- bash -c 
sudo lxc-attach -n $1 -- bash -c "sudo useradd -m admin -p password"

# INSTALL IPTABLES
sudo lxc-attach -n $1 -- bash -c "sudo apt-get update"
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install iptables"

# SET UP EXTERNAL IP
container_ip=$(sudo lxc-info -n $1 -iH)
sudo ip addr add $2/$3 brd + dev enp4s2
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --jump DNAT --to-destination $container_ip
sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $2 

# SET UP PORT DROPPING RULES 

# INSTALL SNOOPY KEYLOGGER
# logs to /var/log/auth.log within the container
# logs to /var/lib/lxc/$1/rootfs/var/log/auth.log on the host system
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install wget -y" 
sudo lxc-attach -n $1 -- bash -c "wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c  "chmod 755 install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c "sudo ./install-snoopy.sh stable" 
sudo lxc-attach -n $1 -- bash -c "rm -rf ./install-snoopy.* snoopy-*"
