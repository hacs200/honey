import re
from datetime import timedelta, datetime
import sys
import subprocess

log_name = sys.argv[1]

commands = []
attack_stream_start = False
attack_stream_end = False
end_found = False
ip_address_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')
session_log = subprocess.run(["zcat", f"/home/honey/MITM/logs/session_streams/{log_name}"], stdout=subprocess.PIPE, text=True)

for line in session_log.stdout.split('\n'):
    if line.find("Container Name") != -1:
        container_parts = line.split()[2]
        full_container_name = container_parts
        container_name = container_parts.split('_')[0] + '_' + container_parts.split('_')[1]
    if line.find("Attacker IP Address") != -1:
        attacker_ip = line.split()[3]
    if line.find("Attack Timestamp") != -1:
        start_time = line.split()[2] + ' ' + line.split()[3]
        start_value = datetime.strptime(start_time, "%Y-%m-%d %H:%M:%S.%f")
    if line.find("Attack End Timestamp") != -1:
        end_time = line.split()[3] + ' ' + line.split()[4]
        end_value = datetime.strptime(end_time, "%Y-%m-%d %H:%M:%S.%f") 
        end_found = True
    if not attack_stream_start:
        if line.find("Attacker Stream Below") != -1:
            attack_stream_start = True
    elif attack_stream_start and not attack_stream_end:
        if line.find("Output Below") != -1:
            attack_stream_end = True
        else:
            if line.find("Noninteractive") == -1:
                commands.append(line)

if not end_found:
    with open(f"/home/honey/MITM/logs/logouts/{full_container_name}.log", "r") as file:
        if line.find(attacker_ip) != -1:
            end_time = line.split(';')[0]
            end_value = datetime.strptime(end_time, "%Y-%m-%d %H:%M:%S.%f")
            end_found = True

if end_found:
    total_time = end_value - start_value
else:
    total_time = "ERROR"
# append total amount of time attacker spent in container to the total_times file for the container
with open(f'data/{container_name}/times/total_times.txt', 'a') as file:
    file.write(attacker_ip + ": " + str(total_time) + ",\n")

# write the commands the attacker ran into the file for that attacker ip for the given container
with open(f'data/{container_name}/commands/{attacker_ip}.txt', 'w') as file:
    for line in commands:
        file.write(line + '\n')
