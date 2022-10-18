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

# make lxc copy of correct container for appropriate scenario
sudo lxc-copy -n $name -N "HONEYPOT_${name}"
fi

# TODO: re-configure iptable rules 

exit 0
