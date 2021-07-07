# linux-scripts
Random collection of basic scripts

## audit.sh
- Intent is that this script can be run directly on a box by a privileged account to gather all key details for that box.  It will call audit1.sh and save the output to a file.

## audit1.sh
- This is the main information gathering script.

## audit_remote.sh
- This will allow an administrator to run the audit script against a range of addresses. As it is using scp/ssh commands, it is recommended that you distribute your keys to each of the hosts.

---

## base_setup.sh
- Intent is that this script is run with the command below, where <aggregator_host_ip> is an "aggregator" box that collects all of the baseline outputs.
- Current assumption is there is an "admin" account that exists and you can SSH into it
- ips.txt should reside in the same directory as this script with a different target host on each line
- Usage: ./base_setup.sh <aggregator_host_ip>

## baseline.sh
- This is the script that will be copied to the target box and executed to collect information
- Output will be saved and SCP'd back to the aggregator box
- Can be run locally, or by means of the base_setup.sh script
- Usage: ./baseline.sh <aggregator_host_ip>
