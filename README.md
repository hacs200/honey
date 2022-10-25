# HACS200 Honeypot Capstone: SSH Warning Banners
Mia Hsu, Jana Liu, Rayn Carrillo, Amelia Talbot

## Honey
Add info here :D maybe you should attack us to find out

## Honeypot Templates
The recycling script relies on creating copies of our honeypot templates. We have four honeypot templates, one for each scenario. Each honeypot template has a different SSH banner. Each template is named in relation to the banner type: <code>template_no_banner</code>, <code>template_low_banner</code>, <code>template_med_banner</code>, and <code>template_high_banner</code>.

In order to create these honeypot templates, we have a script called <code>create.sh</code>.

### <code>create.sh</code>
<code>Usage: ./create.sh</code>

This script takes no arguments.

The script creates each of the four honeypot templates and one copy of each template. This occurs using a loop which repeats 4 times, once for each banner scenario. Each banner scenario is randomly assigned to one of the four external IP addresses that our team was provided. Before the containers are created, firewall rules provided by UMD DIT are established. Then, for each iteration of the loop, the script performs the following actions:

<ol>
  <li> Creates an empty container named <code>template_{scenario}</code> (this is the template container) </li>
  <li> Creates a fake admin user within the template container </li>
  <li> Installs OpenSSH onto the template container </li>
  <li> Copies fake honey files to the template container </li>
  <li> Installs Snoopy keylogger onto the template container </li>
  <li> Adds the appropriate warning banner (depending on the scenario) to the template container </li>
  <li> Makes a copy of the template container named <code>{scenario}_{external ip}</code> (this is the container that attackers will connect to) </li>
  <li> Sets up iptable rules routing the internal honeypot container IP to the assigned external IP </li>
  <li> Begins data collection on the honeypot container </li>
</ol>
  
## Data Collection

### <code>tailing.sh</code>
<code>Usage: ./tailing.sh [scenario_externalip] [datetime]</code>

This script takes two arguments, the name of the container which we need to collect data for and the current date and time. The script touches the log file that will be monitored and calls the <code>inot.sh</code> script, passing in the parameters of the container log file and the external IP address for the container.

### <code>inot.sh</code>
<code>Usage: ./inot.sh [container log file] [scenario_externalip]</code>

We use <code>inotifywait</code> to notice modifications to the copy we maintain of the container's <code>auth.log</code> file. Whenever a modification is made to the log, we check if the log contains information of a user disconnect. If a disconnect occurred, the script immediately calls <code>recycle.sh</code>.

## Recycling
### <code>recycle.sh</code>
<code>Usage: ./recycle.sh [scenario_externalip]</code>

This script takes one argument, the name of the container which must be recycled, and performs the following actions:

<ol>
  <li> Kills the data collection tail process of the container </li>
  <li> Deletes iptable rules for the container </li>
  <li> Stops and destroys the container </li>
  <li> Randomly selects one of the four banner scenarios </li>
  <li> Creates a new container using the template for the chosen banner scenario and the same external IP address as the recycled container </li>
  <li> Configure iptable rules for the new container </li>
  <li> Begin data collection process on new container </li>

</ol>
