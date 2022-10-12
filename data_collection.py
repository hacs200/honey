# This script will be run from the host VM after all files have been transferred to the host.

import re
import datetime
from datetime import timedelta, datetime
import sys

container_name = sys.argv[1]

ip_addresses = []
ip_address_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')

# This file name will need to be changed once we determine what we will be naming the auth.log file we transfer, as well as how often we will be running this script.
with open(f'logs/{container_name}/auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            ip_addresses.append(ip_address_pattern.search(line)[0])

curr_ip_address = ip_addresses.pop()

with open(f'data/{container_name}/last_ip_address.txt', 'w') as file:
    file.write(curr_ip_address)

times = {}
time_pattern = re.compile(r'\b([01]?[0-9]|2[0-3]):([0-5][0-9])(?::([0-9][0-9]))?\b')

with open(f'logs/{container_name}/auth.log', 'r') as file:
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

with open(f'data/{container_name}/times/total_time.txt', 'w') as file:
    file.write('[\n')
    for line in times:
        file.write(line + ": " + times[line] + ",\n")
    file.write("]")

commands = []

with open(f'logs/{container_name}/snoopy.log', 'r') as file:
    for line in file:
        line = line.rsplit(']: ', 1)[1]
        if line.find("Server listening") == -1:
            commands.append(line)

with open(f'data/{container_name}/commands/{curr_ip_address}.txt', 'w') as file:
    for line in commands:
        file.write(line + "\n")

