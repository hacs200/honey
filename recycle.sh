#!/bin/bash

# print usage if incorrect number of arguments provided
if [ $# -ne 1 ]
then
    echo "Usage: ./recycle.sh [container name]"
    exit 1
fi

name=$1	
scenario=$(echo $1 | cut -d '_' -f1,2)
ext_ip=$(echo $1 | cut -d '_' -f3)
container_ip=$(sudo lxc-info -n $name -iH)
tail_pid=$(cat /home/honey/logs/${scenario}/${ext_ip}_tail.txt)
port=$(sudo cat /home/honey/static/ports/${ext_ip}_port.txt)
mask=32

echo "*******************************************************************"
echo "                     RECYCLE SCRIPT TRIGGERED"
echo "*******************************************************************"

# kill tail process
sudo kill $tail_pid
# kill mitm process
sudo forever stop $name
echo "forever stop: $name"
sleep 3

# delete iptable rules
sudo iptables -w --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $container_ip
sudo iptables -w --table nat --delete POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip
sudo iptables -w --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ext_ip --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:$port
sudo ip addr delete $ext_ip/$mask brd + dev enp4s2

# shut down and kill container
sudo lxc-stop -n $name --kill
sudo lxc-destroy -n $name

# pick a random scenario
scenarios=( "no_banner" "low_banner" "med_banner" "high_banner" )
scenarios=( $(shuf -e "${scenarios[@]}"))
new_scenario=${scenarios[0]}
new_name="${new_scenario}_${ext_ip}"
date=$(date "+%F-%H-%M-%S")
# make new container
sudo lxc-copy -n template_${new_scenario} -N $new_name
sudo lxc-start -n $new_name
sudo sleep 20

# sudo lxc-attach -n $n -- bash -c "wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --claim-token wceUolqqD-s5-CjqnwBUOSIZq6pyjwyDlal6eUF3l9uiucH3g9IdrUnfFRhpstkcHaiJm5hjgPAH1YPvXM3DwVk9Y66ed7EKOh3NJDezI_Jtjvk_ichHP9jnD3mWCjh-5m35byI --claim-url https://app.netdata.cloud"

new_container_ip=$(sudo lxc-info -n $new_name -iH)
echo "$new_name: $container_ip, external: $ext_ip"

# set up new iptable rules
#sudo ip link set enp4s2 up
#sudo ip addr add $ext_ip/$mask brd + dev enp4s2
#sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $new_container_ip
#sudo iptables --table nat --insert POSTROUTING --source $new_container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip

# start tailing on new container
sudo /home/honey/tailing.sh $new_name $date

sudo forever -l "/home/honey/logs/${new_scenario}/${date}_${new_name}.log" --id $new_name --append start /home/honey/MITM/mitm.js -n $new_name -i $new_container_ip -p $port --mitm-ip 10.0.3.1 --auto-access --auto-access-fixed 1 --debug

# set up new iptable rules
sudo ip link set enp4s2 up
sudo ip addr add $ext_ip/$mask brd + dev enp4s2
sudo iptables -w --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $new_container_ip
sudo iptables -w --table nat --insert POSTROUTING --source $new_container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip
sudo iptables -w --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:$port

echo "`date "+%F-%H-%M-%S"`: Recycled container $name and made container $new_name, tailpid TRYING NO TAIL" >> /home/honey/logs/recycle.log


exit 0
