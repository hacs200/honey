# HACS200 Honeypot Capstone: SSH Warning Banners
Mia Hsu, Jana Liu, Rayn Carrillo, Amelia Talbot

## Base Honeypots
The recycling script relies on creating copies of our base honeypots. We have 4 base honeypots, one for each scenario. Each base honeypot has a different SSH banner.

In order to create these base honeypots, we have a script called <code>create.sh</code>.

### <code>create.sh</code>
This script takes in 4 arguments:
  <ol>
    <li> Container name </li>
    <li> External IP address </li>
    <li> External network netmask prefix </li>
    <li> Name of the banner message file </li>
  </ol>
  
## Data Collection

### <code>data_collection.sh</code>
This script takes one argument, the name of the container for which data should be collected.

Using the name, the script determines if the container's Snoopy log has been deleted. If not, it copies the log to the host machine. If it has been deleted, it outputs "LOG DELETED" to the file where the Snoopy log would otherwise be stored on the host machine.

This script then calls <code>data_collection.sh</code>

### <code>data_collection.py</code>
This script takes one argument, the name of the container for which data should be collected.

Using the name, the script finds all IP addresses that have connected successfully to the host and stores the final one in <code>data/{container_name}/last_ip_address.txt</code> on the host machine.

The script then calculates the time between the connection and disconnection for each IP address to get the total amount of time the attacker spent in the container and stores the output in <code>data/{container_name}/times/{ip_address_of_attacker}.txt</code>.

The script takes a log of all commands the attacker used and outputs them to <code>data/{container_name}/commands/{ip_address_of_attacker}.txt</code>. If the Snoopy log was deleted, LOG DELETED is written to this file.

## Recycling
### <code>recycle.sh</code>
This script takes one argument, the file path to the file containing the last connected IP address.

Using the file path, the script is able to identify which of the 4 honeypot instantiations needs to be recycled. The script then kills the correct honeypot container and creates a new copy of the honeypot using the appropriate base honeypot.

Since we do not want any IP address to be able to attack a honeypot that has already been visited, we add the last connected IP address to the blacklist for the correct honeypot scenario. Each scenario has its own blacklist to allow the same attacker to attack the other honeypot instantiations.

## Putting It All Together
We have a master script called <code>master_script.sh</code> which is called each time an attacker disconnects from one of our honeypots.

### <code>master_script.sh</code>
This script simply calls both <code>data_collection.sh</code> and <code>recycle.sh</code> with the appropriate parameters. This collects all necessary data from the container which the atacker just disconnected from before then recycling said container.
