#!/bin/bash

sudo tail -f /path/to/container/var/log/auth.log >> logs/our_auth.log &
