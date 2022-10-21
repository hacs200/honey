#!/bin/bash

for i in $(sudo ps | grep inot.sh | cut -d ' ' -f3); do sudo kill $i; done
for i in $(sudo ps | grep inotifywait | cut -d ' ' -f3); do sudo kill $i; done
for i in $(sudo ps | grep "tail" | cut -d ' ' -f3); do sudo kill $i; done
for i in $(sudo lxc-ls); do sudo lxc-stop $i; done
for i in $(sudo lxc-ls); do sudo lxc-destroy $i -f; done
