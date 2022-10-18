#!/bin/bash

# create 4 honeypots for different warnings banners

# $1 = container-name
# $2 = external ip address
# $3 = external network netmask prefix
# $4 = banner message file

#if [ $# -ne 4 ]
#then
#	echo "Usage: ./create.sh [container name] [external ip address] [external network netmask prefix] [banner message]"
#	exit 1
#fi

names=( "no_banner" "low_banner" "med_banner" "high_banner" )
names=( $(shuf -e "${names[@]}")) 
#arr=( "128.8.238.19" "128.8.238.36" "128.8.238.55" "128.8.238.185" "128.8.238.112" )
arr=( "128.8.238.19" "128.8.238.36" "128.8.238.55" "128.8.238.185")

#length=${#names[@]}
length=1
for ((j = 0 ; j < $length; j++));
do
	
	n=${names[$j]}
	ip=${arr[$j]}
	mask=24
	echo "$n"
	echo "$ip"

	exists=$(sudo lxc-ls -1 | grep -w $n | wc -l)
	if [ $exists -ne 0 ]
	then
		sudo lxc-stop $n
		sudo lxc-destroy $n
	fi 

	
	sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n $n -t download -- -d ubuntu -r focal -a amd64
	sudo lxc-start -n $n

	# CREATE FAKE ADMIN USER
	sudo lxc-attach -n $n -- bash -c "sudo useradd -m staff -p password"
	# sudo lxc-attach -n $n -- bash -c "sudo passwd admin"
	# prompt will appear, input desired password
	
	# INSTALL SSH
	sudo lxc-attach -n $n -- bash -c "sudo apt-get install openssh-server"
	sudo lxc-attach -n $n -- bash -c "sudo systemctl enable ssh --now"

	# ADD HONEY TO CONTAINER
	sudo cp -r ./fall2021 ./spring2022 /var/lib/lxc/$n/rootfs/home/admin

	# INSTALL SNOOPY KEYLOGGER
	# logs to /var/log/snoopy.log within the container
	# logs to /var/lib/lxc/$1/rootfs/var/log/snoopy.log on the host system
	sudo lxc-attach -n $n -- bash -c "sudo apt-get install wget -y"
	sudo lxc-attach -n $n -- bash -c "wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
	sudo lxc-attach -n $n -- bash -c  "chmod 755 install-snoopy.sh"
	sudo lxc-attach -n $n -- bash -c "sudo ./install-snoopy.sh stable"
	sudo lxc-attach -n $n -- bash -c "rm -rf ./install-snoopy.* snoopy-*" 
	sudo lxc-attach -n $n -- bash -c "echo output = file:/var/log/snoopy.log >> /etc/snoopy.ini" 

	# INSTALL IPTABLES
	sudo lxc-attach -n $n -- bash -c "sudo apt-get update"
	sudo lxc-attach -n $n -- bash -c "sudo apt-get install iptables"
	sudo lxc-attach -n $n -- bash -c "sudo apt-get install ipset"
	sudo lxc-attach -n $n -- bash -c "sudo ipset create blacklist nethash"

	# SET UP EXTERNAL IP
	container_ip=$(sudo lxc-info -n $n -iH)
	sudo ip link set enp4s2 up  
	sudo ip addr add $ip/$mask brd + dev enp4s2
	sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --jump DNAT --to-destination $container_ip
	sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ip 
	sudo ./firewall.sh
	#sudo ./dit_firewall_rules.sh
	#sudo ./dit_firewall_rules2.sh
	# SET UP PORT DROPPING RULES 
	# sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
	# sudo iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

	# CREATE WARNING BANNER
	cat "warnings/$n.txt" | sudo tee -a /var/lib/lxc/$n/rootfs/etc/motd > /dev/null
done

exit 0
