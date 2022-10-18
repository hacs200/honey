#!/bin/bash

for i in $(sudo lxc-ls); do lxc-stop $i; done
for i in $(sudo lxc-ls); do lxc-destroy $i; done
