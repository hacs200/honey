#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: ./inot.sh [container log file] [container name]"
fi 

file=$1
container=$2

while sudo inotifywait -e modify $file; do
	if cat $1 | grep "Disconnected from user" -q; then
		echo "*******************************************************************"
		echo "			TRIGGERING RECYCLE SCRIPT"
		echo "*******************************************************************"
		echo "`date "+%F-%H-%M-%S"`: Triggering recycle script on container $name" >> /home/honey/logs/inot.log
		sudo /home/honey/recycle.sh $container
		exit 0
	fi
done

