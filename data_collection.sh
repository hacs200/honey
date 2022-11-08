#!/bin/bash

if [/var/lib/lxc/$1/rootfs/var/log/snoopy.log -f]
then
    cp /var/lib/lxc/$1/rootfs/var/log/snoopy.log ./logs/$1/snoopy.log
else
    echo "LOG DELETED" > ./logs/$1/snoopy.log
fi

python3 data_collection.py $1