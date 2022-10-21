#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage ./tailing.sh [container name] [datetime]"
	exit 1
fi
echo $1
echo $2

container=$1
datetime=$2
scenario=$(echo $1 | cut -d '_' -f1,2)
ip=$(echo $1 | cut -d '_' -f3)
# log=$(logs/${scenario}/${datetime}_${container}.log)

sudo tail -f /var/lib/lxc/${container}/rootfs/var/log/auth.log >> logs/${scenario}/${datetime}_${container}.log &

tailpid=$!

echo "ip:$ip"
echo "tail:$tailpid"
echo $tailpid > logs/${scenario}/${ip}_tail.txt

sudo ./inot.sh logs/${scenario}/${datetime}_${container}.log $container &

#sudo tail -f logs/${scenario}/${datetime}_${container}.log | grep "Disconnected from user" -m 1

#sudo ./recycle.sh $container
