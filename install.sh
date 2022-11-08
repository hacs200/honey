#!/bin/bash

if [ $# -ne 1 ]
then
	echo "USAGE: ./install.sh [container name]"
	exit 1
fi

sudo lxc-attach -n $1 -- bash -c "sudo apt-get update"
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install openssh-server -y"
sleep 10
sudo lxc-attach -n $1 -- bash -c "sudo systemctl enable ssh --now"
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install wget -y"
sleep 10
sudo lxc-attach -n $1 -- bash -c "sudo wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c "sudo chmod 755 install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c "sudo ./install-snoopy.sh stable"
sudo lxc-attach -n $1 -- bash -c "sudo rm -rf ./install-snoopy.* snoopy-*"
