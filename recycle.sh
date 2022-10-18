#!/bin/bash

# recycling script will take one argument ($1) for the file path to the file containing only the last connected ip address

# recycling script will be called in another script that occurs immediately after an attacker exits the honeypot

# print usage if incorrect number of arguments provided
if [ $# -ne 1 ]
then
    echo "Usage: ./recycle.sh [file name]"
    exit 1
fi

# file path should be in the form data/{container_name}/last_ip_address.txt
name=`echo $1 | cut -d "/" -f 2`

# shut down and kill container
lxc-stop -n $name --kill

# ADD IF/ELSE IF STATEMENTS FOR EACH CONTAINER
# to make lxc copy of correct container for appropriate scenario
# and to pull the correct blacklisted ip addresses file
if [ $name == 'no_banner' ]
then
    # copy no_banner
elif [ $name == 'low_banner']
then
    # copy low_banner
elif [ $name == 'med_banner']
then
    # copy med_banner
else
    # copy high_banner
fi

sudo ipset flush blacklist

# add ip address to blacklist
file = $(cat $1)
for line in $file
do
    sudo ipset add blacklist $line
done

# set up firewall rules 
lxc-attach -n $name -- iptables -I INPUT -m set --match-set blacklist src -j DROP
lxc-attach -n $name -- iptables -I FORWARD -m set --match-set blacklist src -j DROP

# re-configure MITM 

exit 0
