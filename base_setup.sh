#!/bin/bash

if [[ -z "$1" ]]; then
	echo "Please specify the address of your aggregator box"
	exit 1
else
	aggr=$1
fi

while read host; do
	scp baseline.sh admin@$host:/tmp/baseline.sh
	scp ips.txt admin@$host:/tmp/ips.txt
	ssh admin@$host "/tmp/baseline.sh $aggr"
done < ips.txt
