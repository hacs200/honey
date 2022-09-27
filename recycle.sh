#!/bin/bash

# shut down and kill container
lxc-stop -n container --kill

# create container from snapshot
lxc restore container snap

# add ip address to blacklist
file = $(cat $1)
for line in $file
do
ipset add blacklist $line
done

# set up firewall rules 
lxc-attach -n container -- iptables -I INPUT -m set --match-set blacklist src -j DROP
lxc-attach -n container -- iptables -I FORWARD -m set --match-set blacklist src -j DROP
