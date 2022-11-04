#!/bin/bash

# kill processes
for i in $(sudo ps -e | grep inot.sh | awk '{print $1}'); do sudo kill $i; done
for i in $(sudo ps -e | grep inotifywait | awk '{print $1}'); do sudo kill $i; done
#sudo forever stopall
sudo pm2 stop all
sudo pm2 delete all
for i in $(sudo ps -e | grep "tail" | awk '{print $1}'); do sudo kill $i; done
for i in $(sudo ps -e | grep node | awk '{print $1}';); do sudo kill $i; done
# kill containers
for i in $(sudo lxc-ls); do sudo lxc-stop $i; done
for i in $(sudo lxc-ls); do sudo lxc-destroy $i -f; done

#for i in $(sudo ps -aux | grep inotifywait | cut -d ' ' -f3); do sudo kill $i; done
#for i in $(sudo ps -aux | grep inot.sh | cut -d ' ' -f3); do sudo kill $i; done
#for i in $(sudo forever list | tail -n+5 | grep "/usr/bin/node" | tr -s ' ' | cut -d ' ' -f18); do sudo kill $i; done
#for i in $(sudo ps -aux | grep "tail" | tr -s ' ' | cut -d ' ' -f2); do sudo kill $i; done
