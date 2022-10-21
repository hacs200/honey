#!/bin/bash
while inotifywait -e modify $1; do
	if cat $1 | grep "Disconnected from user" -q; then
		echo "*******************************************************************"
		echo "TRIGGERING RECYCLE SCRIPT"
		echo "*******************************************************************"
		sudo ./recycle.sh $2
		exit 0
	fi
done

