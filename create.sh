#!/bin/bash

sudo iptables-restore ./iptables.txt
sudo ./delete.sh

names=( "template_no_banner" "template_low_banner" "template_med_banner" "template_high_banner" )
arr=( "128.8.238.19" "128.8.238.36" "128.8.238.55" "128.8.238.185")
arr=( $(shuf -e "${arr[@]}")) 
pots=( "no_banner" "low_banner" "med_banner" "high_banner" )
mitm_ports=( "10000" "20000" "30000" "40000" )
 
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo sysctl -w net.ipv4.ip_forward=1


length=1
for ((j = 0 ; j < $length; j++));
do
	
	n=${names[$j]}
	ip=${arr[$j]}
	mask=32
	exists=$(sudo lxc-ls -1 | grep -w $n | wc -l)
	if [ $exists -ne 0 ]
	then
		sudo lxc-stop $n
		sudo lxc-destroy $n
	fi 

	
	sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n $n -t download -- -d ubuntu -r focal -a amd64
	sudo lxc-start -n $n

	# CREATE FAKE ADMIN USER
	sudo lxc-attach -n $n -- bash -c "sudo useradd -m user"
	sudo lxc-attach -n $n -- bash -c "echo user:password | sudo chpasswd"
	
	# INSTALL SSH
	sudo lxc-attach -n $n -- bash -c "sudo apt-get install openssh-server"
	sudo lxc-attach -n $n -- bash -c "sudo systemctl enable ssh --now"

	# ADD HONEY TO CONTAINER
	sudo cp -r ./fall2021 ./spring2022 /var/lib/lxc/$n/rootfs/home/user

	# INSTALL SNOOPY KEYLOGGER
	# logs to /var/log/snoopy.log within the container
	# logs to /var/lib/lxc/$1/rootfs/var/log/snoopy.log on the host system
	#sudo lxc-attach -n $n -- bash -c "sudo apt-get install wget -y"
	#sudo lxc-attach -n $n -- bash -c "wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
	#sudo lxc-attach -n $n -- bash -c  "chmod 755 install-snoopy.sh"
	#sudo lxc-attach -n $n -- bash -c "sudo ./install-snoopy.sh stable"
	#sudo lxc-attach -n $n -- bash -c "rm -rf ./install-snoopy.* snoopy-*" 
	#sudo lxc-attach -n $n -- bash -c "echo output = file:/var/log/snoopy.log >> /etc/snoopy.ini" 

	# CREATE WARNING BANNER
	cat "warnings/$n.txt" | sudo tee -a /var/lib/lxc/$n/rootfs/etc/motd > /dev/null
	sudo lxc-stop -n $n
		
	# CREATE INITIAL COPY OF THE TEMPLATE
	pot=${pots[$j]}
	sudo lxc-copy -n $n -N $pot
	sudo lxc-start -n $pot
	sudo sleep 30

	# SET UP COPY's FIREWALL RULES
	container_ip=$(sudo lxc-info -n $pot -iH)
	echo "$pot: $container_ip, external: $ip"
	
	mitm_path="/home/honey/logs/$pot"
	#port=6500
	port=${mitm_ports[$j]}
	sudo forever -l $mitm_path/$container_ip.log --append start /home/honey/MITM/mitm.js -n $pot -i $container_ip -p $port --auto-access --auto-access-fixed 3 --debug
	
	# SET UP COPY's FIREWALL RULES
	#sudo ip link set enp4s2 up  
	#sudo ip addr add $ip/$mask brd + dev enp4s2
	#sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --jump DNAT --to-destination $container_ip
	#sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ip 

	# prerouting
	sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --jump DNAT --to-destination $container_ip

	# prerouting from external ip to mitm server
	sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip --protocol tcp --dport 22 --jump DNAT --to-destination "127.0.0.1:$port" 
	
	# postrouting from container to external 
	sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ip 
	sudo iptables --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ip
	
	sudo lxc-attach -n "$pot" -- bash -c "cd /etc/security && echo '*       hard    maxsyslogins    1' >> limits.conf && echo 'root hard    maxlogins   1' >> limits.conf"

	sudo ./tailing.sh $pot
done
#sudo ./firewall.sh

exit 0
