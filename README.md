# linux-scripts
Random collection of basic scripts

##base_setup.sh
- Intent is that this script is run with the command below, where <aggregator_host_ip> is an "aggregator" box that collects all of the baseline outputs.
- Current assumption is there is an "admin" account that exists and you can SSH into it
- ips.txt should reside in the same directory as this script with a different target host on each line
- Usage: ./base_setup.sh <aggregator_host_ip>

##baseline.sh
- This is the script that will be copied to the target box and executed to collect information
- Output will be saved and SCP'd back to the aggregator box
- Can be run locally, or by means of the base_setup.sh script
- Usage: ./baseline.sh <aggregator_host_ip>
