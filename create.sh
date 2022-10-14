#!/bin/bash

# $1 = container-name
# $2 = external ip address
# $3 = external network netmask prefix
# $4 = banner message file

if [ $# -ne 4 ]
then
	echo "Usage: ./create.sh [container name] [external ip address] [external network netmask prefix] [banner message]"
	exit 1
fi

# CREATE CONTAINER
sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n $1 -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n $1

# CREATE FAKE ADMIN USER
sudo lxc-attach -n $1 -- bash -c 
sudo lxc-attach -n $1 -- bash -c "sudo useradd -m admin -p password"

# INSTALL SSH
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install openssh-server"
sudo lxc-attach -n $1 -- bash -c "sudo systemctl enable ssh --now"

# ADD HONEY TO CONTAINER
sudo cp -r ./fall2021 ./spring2022 /var/lib/lxc/$1/rootfs/home/admin

# INSTALL SNOOPY KEYLOGGER
# logs to /var/log/snoopy.log within the container
# logs to /var/lib/lxc/$1/rootfs/var/log/snoopy.log on the host system
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install wget -y"
sudo lxc-attach -n $1 -- bash -c "wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c  "chmod 755 install-snoopy.sh"
sudo lxc-attach -n $1 -- bash -c "sudo ./install-snoopy.sh stable"
sudo lxc-attach -n $1 -- bash -c "rm -rf ./install-snoopy.* snoopy-*" 
sudo lxc-attach -n $1 -- bash -c "echo output = file:/var/log/snoopy.log >> /etc/snoopy.ini" 

# INSTALL IPTABLES
sudo lxc-attach -n $1 -- bash -c "sudo apt-get update"
sudo lxc-attach -n $1 -- bash -c "sudo apt-get install iptables"

# SET UP EXTERNAL IP
container_ip=$(sudo lxc-info -n $1 -iH)
sudo ip link set enp4s2 up  
sudo ip addr add $2/$3 brd + dev enp4s2
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $2 --jump DNAT --to-destination $container_ip
sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $2 

# SET UP PORT DROPPING RULES 
# sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
# sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# CREATE WARNING BANNER
sudo lxc-attach -n $1 -- bash -c "cat $4 >> /etc/motd"
