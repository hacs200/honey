import re

ip_addresses = []
ip_address_pattern = re.compile(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})')

with open('../../auth.log', 'r') as file:
    for line in file:
        if line.find("Accepted password") != -1:
            ip_addresses.append(ip_address_pattern.search(line)[0])

print(ip_addresses)
