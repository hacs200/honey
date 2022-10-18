#!/bin/bash

# recycling script will take one argument ($1) for the file path to the file containing only the last connected ip address

# recycling script will be called in another script that occurs immediately after an attacker exits the honeypot

# print usage if incorrect number of arguments provided
if [ $# -ne 1 ]
then
    echo "Usage: ./recycle.sh [file name]"
    exit 1
fi

# file path provided as arugment should be in the form data/{container_name}/last_ip_address.txt
# extract container name to a variable (name)
name=`echo $1 | cut -d "/" -f 2`

# shut down and kill container
sudo lxc-stop -n $name --kill

# pull the correct blacklisted ip addresses file
# make lxc copy of correct container for appropriate scenario
if [ $name == 'no_banner' ]
then
    file="/home/honey/data/no_banner/last_ip_address.txt"
    sudo lxc-copy -n no_banner -N HONEYPOT_no
elif [ $name == 'low_banner']
then
    file="/home/honey/data/low_banner/last_ip_address.txt"
    sudo lxc-copy -n low_banner -N HONEYPOT_low
elif [ $name == 'med_banner']
then
    file="/home/honey/data/med_banner/last_ip_address.txt"
    sudo lxc-copy -n med_banner -N HONEYPOT_med
else
    file="/home/honey/data/high_banner/last_ip_address.txt"
    sudo lxc-copy -n high_banner -N HONEYPOT_high
fi

# clear blacklist
sudo ipset flush blacklist

# add ip address to blacklist
for line in $file
do
    sudo lxc-attach -n $name -- bash -c "ipset add blacklist $line"
done

# set up firewall rules
sudo lxc-attach -n $name -- bash -c "iptables -I INPUT -m set --match-set blacklist src -j DROP"
sudo lxc-attach -n $name -- bash -c "iptables -I FORWARD -m set --match-set blacklist src -j DROP"

# TODO: re-configure MITM 

exit 0
