#!/bin/bash

day=$1

files=$(find /home/honey/MITM/logs/session_streams/ -name "$day*" | cut -d '/' -f 7)
#echo $files

for file in $files; do
	sudo python3 data_parsing.py $file
done

tar cvzf /mnt/sdb/$day.tar.gz /home/honey/MITM/logs/session_streams/$day*

for file in $files; do
	sudo rm /home/honey/MITM/logs/session_streams/$file
done
#for file in "/home/honey/logs/no_banner/$day*"; do

#	file=$(cut -d '/' -f 6 $file)
#	sudo python3 mitm_data_parsing.py file
#done

#for file in "/home/honey/logs/low_banner/$day*"; do
#	echo $file
#done
