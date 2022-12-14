#!/bin/bash

#sudo modprobe br_netfilter
#sudo sysctl -p /etc/sysctl.conf

sudo iptables-restore /home/honey/iptables.txt
sudo /home/honey/delete.sh
sudo /home/honey/firewall.sh

#templates=( "template_no_banner" "template_low_banner" "template_med_banner" "template_high_banner" )
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
sudo lxc-attach -n template -- bash -c "echo root:password | sudo chpasswd"
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

# INSTALL SNOOPY KEYLOGGER
# sudo lxc-attach -n template -- bash -c "sudo apt-get install wget -y"
# sleep 10
# sudo lxc-attach -n template -- bash -c "sudo wget -O install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh"
# sudo lxc-attach -n template -- bash -c "sudo chmod 755 install-snoopy.sh"
# sudo lxc-attach -n template -- bash -c "sudo ./install-snoopy.sh stable"
# sudo lxc-attach -n template -- bash -c "sudo rm -rf ./install-snoopy.* snoopy-*" 
# sudo lxc-attach -n template -- bash -c "wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --claim-token wceUolqqD-s5-CjqnwBUOSIZq6pyjwyDlal6eUF3l9uiucH3g9IdrUnfFRhpstkcHaiJm5hjgPAH1YPvXM3DwVk9Y66ed7EKOh3NJDezI_Jtjvk_ichHP9jnD3mWCjh-5m35byI --claim-url https://app.netdata.cloud"


sudo lxc-stop -n template
# *********************** #

LENGTH=2
for ((j = 0 ; j < $LENGTH; j++));
do
	scenario=${scenarios[$j]}
	n="template_${scenario}"
	
	# CREATE COPY OF BASE TEMPLATE
	sudo lxc-copy -n template -N $n
	sleep 10

	# ADD WARNING BANNER
	cat "/home/honey/static/warnings/$scenario.txt" | sudo tee -a /var/lib/lxc/$n/rootfs/etc/motd > /dev/null
	sudo lxc-start -n $n
	sudo lxc-attach -n $n -- bash -c "echo 'Banner /etc/motd' >> /etc/ssh/sshd_config"	
	# echo "Banner /home/honey/static/warnings/${scenario}.txt" >> /var/lib/lxc/$n/rootfs/etc/ssh/sshd_config
	sudo lxc-attach -n $n -- bash -c "sudo systemctl reload ssh.service"
	sudo lxc-stop -n $n		
done


sudo lxc-copy -n template_low_banner -N jana2
# *********************** #
# CREATE ACTUAL HONEYPOTS #
exit 0
