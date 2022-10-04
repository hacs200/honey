# This script will be run from the host VM after all files have been transferred to the host.

import re
import datetime
import time
from datetime import date, timedelta, datetime

ip_addresses = []
ip_address_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')

# This file name will need to be changed once we determine what we will be naming the auth.log file we transfer, as well as how often we will be running this script.
with open('auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            ip_addresses.append(ip_address_pattern.search(line)[0])

# Might consider writting these IP addresses to another file and using that file for the addition of firewall rules preventing the return of past attackers
print(ip_addresses)

times = {}
time_pattern = re.compile(r'\b([01]?[0-9]|2[0-3]):([0-5][0-9])(?::([0-9][0-9]))?\b')

with open('auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            start_time = time_pattern.search(line)[0]
            times[ip_address_pattern.search(line)[0]] = start_time
        elif line.find("Received disconnect") != -1:
            start_time = times.get(ip_address_pattern.search(line)[0])
            if start_time != None:
                end_time = time_pattern.search(line)[0]
                # Converted our start and end time values to datetime objects
                end_values = datetime.strptime(end_time, "%H:%M:%S")
                start_values = datetime.strptime(start_time, "%H:%M:%S")
                total_time = end_values - start_values
                # Makes sure there isn't a negative value when subtracting the timestamps
                if total_time.days < 0:
                    total_time = timedelta(
                        days = 0,
                        seconds = total_time.seconds,
                        microseconds = total_time.microseconds
                    )
                # Puts the total time into "Hour:Minute:Second" format by using the str method
                times[ip_address_pattern.search(line)[0]] = str(total_time)

# We will need to figure out how we want to store this long term
print(times)

commands = []

with open('snoopy.log', 'r') as file:
    for line in file:
        line = line.rsplit(']: ', 1)[1]
        if line.find("Server listening") == -1:
            commands.append(line)

# Need to determine how to store this long term
print(commands)

