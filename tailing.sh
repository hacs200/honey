#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: ./tailing.sh [container name] [datetime]"
	exit 1
fi

container=$1
datetime=$2
scenario=$(echo $1 | cut -d '_' -f1,2)
ip=$(echo $1 | cut -d '_' -f3)

# copy contents of container's auth.log to host
# tail -f /var/lib/lxc/${container}/rootfs/var/log/auth.log >> /home/honey/logs/${scenario}/${datetime}_${container}.log &
# tailpid=$!

# echo "ip: $ip, tail: $tailpid"
# echo $tailpid > /home/honey/logs/${scenario}/${ip}_tail.txt

# create log file
sudo touch /home/honey/logs/${scenario}/${datetime}_${container}.log

# call script that triggers ./recycle.sh 
sudo /home/honey/inot.sh /home/honey/logs/${scenario}/${datetime}_${container}.log $container &
