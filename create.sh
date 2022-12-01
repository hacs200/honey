#!/bin/bash

sudo iptables-restore /home/honey/iptables.txt
sudo /home/honey/delete.sh
sudo /home/honey/firewall.sh

ips=( "128.8.238.19" "128.8.238.36" "128.8.238.55" "128.8.238.185")
ips=( $(shuf -e "${ips[@]}")) 
scenarios=( "no_banner" "low_banner" "med_banner" "high_banner" )
users=( "admin" "test" "a" "guest" "user" "oracle" "postgres" "webmaster" "mysql" )
 
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
sudo sysctl -w net.ipv4.ip_forward=1

# ********************** #
#  CREATE BASE TEMPLATE  #
# ********************** #

sudo DOWNLOAD_KEYSERVER="keyserver.ubuntu.com" lxc-create -n template -t download -- -d ubuntu -r focal -a amd64
sudo lxc-start -n template

# ADD USERS
USERS=9
for ((j = 0 ; j < $USERS; j++));
do
	# CREATE USER
	user=${users[$j]}
	sudo lxc-attach -n template -- bash -c "sudo useradd -m ${user}"
	sudo lxc-attach -n template -- bash -c "echo ${user}:password | sudo chpasswd"

	# ADD HONEY TO TEMPLATE
	sudo cp -r /home/honey/static/fall2021 /home/honey/static/spring2022 /var/lib/lxc/template/rootfs/home/${user}
done
sudo cp -r /home/honey/static/fall2021 /home/honey/static/spring2022 /var/lib/lxc/template/rootfs/root

# INSTALL SSH
sudo lxc-attach -n template -- bash -c "sudo apt-get update"
sleep 10
sudo lxc-attach -n template -- bash -c "sudo apt-get install openssh-server -y"
sleep 10
sudo lxc-attach -n template -- bash -c "sudo systemctl enable ssh --now"
# allow root ssh 
sudo lxc-attach -n template -- bash -c "echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config"
sudo lxc-attach -n template -- bash -c "systemctl restart sshd"
 
# sudo lxc-attach -n template -- bash -c "cd /etc/security && echo '*       hard    maxsyslogins    1' >> limits.conf && echo 'root hard    maxlogins   1' >> limits.conf"

sudo lxc-stop -n template

# *********************** #
# CREATE BANNER TEMPLATES #
# *********************** #

LENGTH=4
for ((j = 0 ; j < $LENGTH; j++));
do
	scenario=${scenarios[$j]}
	n="template_${scenario}"
	
	# CREATE COPY OF BASE TEMPLATE
	sudo lxc-copy -n template -N $n
	sleep 10

	# ADD WARNING BANNER
	cat "/home/honey/static/warnings/$scenario.txt" | sudo tee -a /var/lib/lxc/$n/rootfs/etc/motd > /dev/null
	
	sudo lxc-stop -n $n		
done

# *********************** #
# CREATE ACTUAL HONEYPOTS #
# *********************** #

for ((j = 0 ; j < $LENGTH; j++));
do
	ext_ip=${ips[$j]}
	scenario=${scenarios[$j]}
	template="template_${scenario}"
	n="${scenario}_${ext_ip}" # name of the honeypot being deployed
	mask=32
	date=$(date "+%F-%H-%M-%S")
		
	# CREATE HONEYPOT 
	sudo lxc-copy -n $template -N $n
	sudo lxc-start -n $n
	
	sudo sleep 20
	
	container_ip=$(sudo lxc-info -n $n -iH)
	echo "container: $n, container_ip: $container_ip, external_ip: $ext_ip"

	# SET UP MITM
	port=$(sudo cat /home/honey/static/ports/${ext_ip}_port.txt)
	
	sudo pm2 -l "/home/honey/logs/${scenario}/${date}_${n}.log" start /home/honey/MITM/mitm.js --name $n -- -n $n -i $container_ip -p $port --mitm-ip 10.0.3.1 --auto-access --auto-access-fixed 1 --debug --ssh-server-banner-file /home/honey/static/warnings/${scenario}.txt
	
	# SET UP HONEYPOT's FIREWALL RULES
	sudo ip link set enp4s2 up  
	sudo ip addr add $ext_ip/$mask brd + dev enp4s2
	# prerouting
	sudo iptables -w --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $container_ip
	# postrouting
	sudo iptables -w --table nat --insert POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip
	# prerouting from external to mitm server
	sudo iptables -w --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --protocol tcp --dport 22 --jump DNAT --to-destination "10.0.3.1:$port" 
	sudo sysctl -w net.ipv4.conf.all.route_localnet=1

	# START HONEYPOT DATA COLLECTION
	datetime=$(date)
	sudo touch /home/honey/logs/${scenario}/${datetime}_${n}.log
	sudo /home/honey/inot.sh /home/honey/logs/${scenario}/${datetime}_${n}.log $n &
done

exit 0
