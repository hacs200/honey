#!/bin/bash

sudo tail -f /var/lib/lxc/$1/rootfs/var/log/auth.log >> logs/$1/auth.log &
