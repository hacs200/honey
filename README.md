# HACS200 Honeypot Capstone: SSH Warning Banners
Mia Hsu, Jana Liu, Rayn Carrillo, Amelia Talbot

## Honeypot Templates
The recycling script relies on creating copies of our honeypot templates. We have 4 honeypot templates, one for each scenario. Each honeypot template has a different SSH banner. They are named in relation to their banner, with names being <code>no_banner</code>, <code>low_banner</code>, <code>med_banner</code>, and <code>high_banner</code>.

In order to create these honeypot templates, we have a script called <code>create.sh</code>.

### <code>create.sh</code>
This script takes in no argument. It creates each of the honeypot templates as well as the first set copies, randomly assigning them to each of the four IP addresses given to us. It configures firewall rules following DIT firewall rules, leaving port 22 open for SSH purposes. The templates are named as <code>template_{banner scenario}<\code>. The copies of each container are named as <code>{scenario}_{external ip}<\code>.
  
## Data Collection

### <code>tailing.sh</code>
This script takes one argument, the name of the container for which the <code>auth.log</code> should be tailed. This process is run in the background and outputs to <code>logs/{banner scenario}/{date/time_containername}.log<\code>. The containername used to name the file contains the public facing IP and the scenario name.

### <code>data_collection.sh</code>
#### THE USE OF THIS SCRIPT IS DEPRECATED. IT MUST BE UPDATED TO CORRECTLY PARSE DATA.
This script takes one argument, the name of the container for which data should be collected.

Using the name, the script determines if the container's Snoopy log has been deleted. If not, it copies the log to the host machine. If it has been deleted, it outputs "LOG DELETED" to the file where the Snoopy log would otherwise be stored on the host machine, at <code>logs/{container_name}/snoopy.log</code>.

This script then calls <code>data_collection.sh</code>

### <code>data_collection.py</code>
#### THE USE OF THIS SCRIPT IS DEPRECATED. IT MUST BE UPDATED TO CORRECTLY PARSE DATA.
This script takes one argument, the name of the container for which data should be collected.

Using the name, the script finds all IP addresses that have connected successfully to the host and stores the final one in <code>data/{container_name}/last_ip_address.txt</code> on the host machine.

The script then calculates the time between the connection and disconnection for each IP address to get the total amount of time the attacker spent in the container and stores the output in <code>data/{container_name}/times/total_times.txt</code>.

The script takes a log of all commands the attacker used and outputs them to <code>data/{container_name}/commands/{ip_address_of_attacker}.txt</code>. If the Snoopy log was deleted, LOG DELETED is written to this file.

## Recycling
### <code>recycle.sh</code>
#### This portion needs to be updated.
This script takes one argument, the file path to the file containing the last connected IP address.

Using the file path, the script is able to identify which of the 4 honeypot instantiations needs to be recycled. The script then kills the correct honeypot container and creates a new copy of the honeypot using the appropriate honeypot template.

## Putting It All Together
We have a master script called <code>master_script.sh</code> which is called each time an attacker disconnects from one of our honeypots.

### <code>master_script.sh</code>
#### This portion needs to be updated.
This script simply calls both <code>data_collection.sh</code> and <code>recycle.sh</code> with the appropriate parameters. This collects all necessary data from the container which the atacker just disconnected from before then recycling said container.
