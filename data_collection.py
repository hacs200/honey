# This script will be run from the host VM after all files have been transferred to the host.

import re
import time

ip_addresses = []
ip_address_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')

# This file name will need to be changed once we determine what we will be naming the auth.log file we transfer, as well as how often we will be running this script.
with open('../logs/auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            ip_addresses.append(ip_address_pattern.search(line)[0])

# Might consider writting these IP addresses to another file and using that file for the addition of firewall rules preventing the return of past attackers
print(ip_addresses)

times = {}
time_pattern = re.compile(r'\b([01]?[0-9]|2[0-3]):([0-5][0-9])(?::([0-9][0-9]))?\b')

with open('../logs/auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            start_time = time_pattern.search(line)[0]
            times[ip_address_pattern.search(line)[0]] = start_time
        elif line.find("Received disconnect") != -1:
            start_time = times.get(ip_address_pattern.search(line)[0])
            if start_time != None:
                end_time = time_pattern.search(line)[0]
                end_values = end_time.split(':')
                start_values = start_time.split(':')
                total_time = ''
                # Need to figure out how to prevent negative values
                for value in range(0, 3):
                    total_time += str(int(end_values[value]) - int(start_values[value]))
                    total_time += ":"
                total_time = total_time.rstrip(total_time[-1])
                times[ip_address_pattern.search(line)[0]] = total_time

# We will need to figure out how we want to store this long term
print(times)

commands = []

with open('../logs/snoopy.log', 'r') as file:
    for line in file:
        line = line.rsplit(']: ', 1)[1]
        if line.find("Server listening") == -1:
            commands.append(line)

# Need to determine how to store this long term
print(commands)

