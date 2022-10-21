#!/bin/bash

sudo iptables-restore /home/honey/iptables.txt
sudo /home/honey/delete.sh

templates=( "template_no_banner" "template_low_banner" "template_med_banner" "template_high_banner" )
ips=( "128.8.238.19" "128.8.238.36" "128.8.238.55" "128.8.238.185")
ips=( $(shuf -e "${ips[@]}")) 
scenarios=( "no_banner" "low_banner" "med_banner" "high_banner" )
 
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo sysctl -w net.ipv4.ip_forward=1

LENGTH=4
for ((j = 0 ; j < $LENGTH; j++));
do
	
	ext_ip=${ips[$j]}
	template=${templates[$j]}
	scenario=${scenarios[$j]}
	n="${scenario}_${ext_ip}" # name of the honeypot being deployed
	mask=32

	# stops and destroys if template already exists
	exists=$(sudo lxc-ls -1 | grep -w $template | wc -l)
	if [ $exists -ne 0 ]
	then
		sudo lxc-stop $template
		sudo lxc-destroy $template
	fi 

	# CREATING SCENARIO TEMPLATE	
	sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n $template -t download -- -d ubuntu -r focal -a amd64
	sudo lxc-start -n $template

	# CREATE FAKE ADMIN USER
	sudo lxc-attach -n $template -- bash -c "sudo useradd -m user"
	sudo lxc-attach -n $template -- bash -c "echo user:password | sudo chpasswd"
	
	# INSTALL SSH
	sudo lxc-attach -n $template -- bash -c "sudo apt-get update"
	sleep 10
	sudo lxc-attach -n $template -- bash -c "sudo apt-get install openssh-server -y"
	sleep 10
	sudo lxc-attach -n $template -- bash -c "sudo systemctl enable ssh --now"

	# ADD HONEY TO TEMPLATE
	sudo cp -r ./fall2021 ./spring2022 /var/lib/lxc/$template/rootfs/home/user

	# INSTALL SNOOPY KEYLOGGER
	# logs to /var/log/snoopy.log within the container
	# logs to /var/lib/lxc/$1/rootfs/var/log/snoopy.log on the host system
	sudo lxc-attach -n $template -- bash -c "sudo apt-get install wget -y"
	sleep 10
	sudo lxc-attach -n $template -- bash -c "sudo wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
	sudo lxc-attach -n $template -- bash -c "sudo chmod 755 install-snoopy.sh"
	sudo lxc-attach -n $template -- bash -c "sudo ./install-snoopy.sh stable"
	sudo lxc-attach -n $template -- bash -c "sudo rm -rf ./install-snoopy.* snoopy-*" 

	# ADD WARNING BANNER
	cat "/home/honey/warnings/$scenario.txt" | sudo tee -a /var/lib/lxc/$template/rootfs/etc/motd > /dev/null
	sudo lxc-stop -n $template
		
	# CREATE HONEYPOT (COPY OF THE TEMPLATE)
	sudo lxc-copy -n $template -N $n
	sudo lxc-start -n $n
	
	sudo sleep 20

	container_ip=$(sudo lxc-info -n $n -iH)
	echo "container: $n, container_ip: $container_ip, external_ip: $ext_ip"
	
	# SET UP HONEYPOT's FIREWALL RULES
	sudo ip link set enp4s2 up  
	sudo ip addr add $ext_ip/$mask brd + dev enp4s2
	sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $container_ip
	sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip 

	# START HONEYPOT DATA COLLECTION
	sudo /home/honey/tailing.sh $n $(date "+%F-%H-%M-%S")
done

sudo /home/honey/firewall.sh

exit 0
