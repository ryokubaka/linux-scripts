#!/bin/bash

if [[ -z "$1" ]]; then
	echo "Please specify the IP address of your aggregator box"
	exit 1
fi

if [[ ! -d "/tmp/results" ]]; then
	mkdir /tmp/results
fi

cd /tmp/

while read host; do
	echo "======== Header ==========" > results/baseline_$host
	hostname >> results/baseline_$host
	ip a >> results/baseline_$host
	timedatectl >> results/baseline_$host
	echo "=====================================================" >> results/baseline_$host

	echo " ======== File system disk space usage (lsblk) =======" >> results/baseline_$host
	lsblk >> results/baseline_$host
	echo "=====================================================" >> results/baseline_$host

	echo "========= Mounts (/etc/fstab) ===========" >> results/baseline_$host
	cat /etc/fstab >> results/baseline_$host
# If there is a boot partition, consider adding 'LABEL=/boot <fs_format> defaults,ro 1 2' to lock boot partition to read only
	echo "=====================================================" >> results/baseline_$host

	if [ -f "/etc/debian_version" ]; then
		echo "========= Packages (debian) ===============================================" > results/packages_$host
		dpkg-query -f '${binary:Package}\n' -W >> results/packages_$host
		echo "=========================================================" >> results/packages_$host
	fi

	if [ -f "/etc/centos-release" ]; then
		echo "========= Packages (CentOS) ===========" > results/packages_$host
		yum list installed >> results/packages_$host
		echo "========================================================" >> results/packages_$host
	fi

	echo "========= Listening Ports ============" >> results/baseline_$host
	netstat -ntlpu >> results/baseline_$host
	echo "======================================================" >> results/baseline_$host

	echo "========= SELinux State (RHEL/CentOS only) ===========" >> results/baseline_$host
	systemctl get-enforce >> results/baseline_$host
	echo "=====================================================" >> results/baseline_$host

	echo "========= Contents of /etc/sysctl.conf ===============================================" >> results/baseline_$host
	cat /etc/sysctl.conf >> results/baseline_$host
# Consider adding 'hard core 0' to prevent system creating core dumps when OS terminates a program due to SEGV or other error
	echo "=====================================================" >> results/baseline_$host

	echo "========= Contents of /etc/crontab ==========" >> results/baseline_$host
	cat /etc/crontab >> results/baseline_$host
	echo "====================================================" >> results/baseline_$host

	echo "========== Contents of /etc/cron.* ==========" >> results/baseline_$host
	for file in /etc/cron.d/*; do
		echo "========================================================================" >> results/baseline_$host
		ls -la $file >> results/baseline_$host
		cat $file >> results/baseline_$host
	done
	echo "====================================================" >> results/baseline_$host

	echo "========== Contents of /etc/ssh/sshd_config ==========" >> results/baseline_$host
	cat /etc/ssh/sshd_config >> results/baseline_$host
	echo "====================================================" >> results/baseline_$host

	echo "========== Contents of /etc/pam.d files ===========" >> results/baseline_$host
	for file in /etc/pam.d/*; do
		echo "===============================================" >> results/baseline_$host
		ls -la $file >> results/baseline_$host
		cat $file >> results/baseline_$host
	done
	echo "====================================================" >> results/baseline_$host
# Consider adding 'auth required pam_wheel.so use_uid to pam.d/su file to restrict su to wheel users
# Consider adding 'auth sufficient pam_unix.so likeauth nullok' and 'password sufficient pam_unix.so remember=4' to not allow reuse of last 4 passwords

done < ips.txt

ssh admin@$1 "mkdir /tmp/results"
scp results/* admin@$1:/tmp/results/
