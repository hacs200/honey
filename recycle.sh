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
tail_pid=$(cat logs/${scenario}/${ext_ip}_tail.txt)

echo "*******************************************************************"
echo "                     RECYCLE SCRIPT TRIGGERED"
echo "*******************************************************************"
# kill tail process
sudo kill $tail_pid

# delete iptable rules
sudo iptables -w --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $container_ip
sudo iptables -w --table nat --delete POSTROUTING --source $container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip

# shut down and kill container
sudo lxc-stop -n $name --kill
sudo lxc-destroy -n $name

# pick a random scenario
scenarios=( "no_banner" "low_banner" "med_banner" "high_banner" )
scenarios=( $(shuf -e "${scenarios[@]}"))
new_scenario=${scenarios[0]}

if [ `sudo lxc-ls | wc | tr -s ' ' | cut -d ' ' -f3` -lt 8 ]
then
        new_scenario="no_banner"
else
        new_scenario=${scenarios[0]}
fi

new_name="${new_scenario}_${ext_ip}"



# make new container
sudo lxc-copy -n template_${new_scenario} -N $new_name
sudo lxc-start -n $new_name
sudo sleep 30

# sudo lxc-attach -n $n -- bash -c "wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh --claim-token wceUolqqD-s5-CjqnwBUOSIZq6pyjwyDlal6eUF3l9uiucH3g9IdrUnfFRhpstkcHaiJm5hjgPAH1YPvXM3DwVk9Y66ed7EKOh3NJDezI_Jtjvk_ichHP9jnD3mWCjh-5m35byI --claim-url https://app.netdata.cloud"

new_container_ip=$(sudo lxc-info -n $new_name -iH)
mask=32
echo "$new_name: $container_ip, external: $ext_ip"

# set up new iptable rules
#sudo ip link set enp4s2 up
#sudo ip addr add $ext_ip/$mask brd + dev enp4s2
#sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $new_container_ip
#sudo iptables --table nat --insert POSTROUTING --source $new_container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip

# start tailing on new container
sudo /home/honey/tailing.sh $new_name $(date "+%F-%H-%M-%S")

# set up new iptable rules
sudo ip link set enp4s2 up
sudo ip addr add $ext_ip/$mask brd + dev enp4s2
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ext_ip --jump DNAT --to-destination $new_container_ip
sudo iptables --table nat --insert POSTROUTING --source $new_container_ip --destination 0.0.0.0/0 --jump SNAT --to-source $ext_ip
exit 0
