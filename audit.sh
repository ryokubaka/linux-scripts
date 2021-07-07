#!/bin/sh 
############################################################
### /secure/audit.sh                                     ###
###                                                      ###
### FUNCTION: Call  main audit script: audit1.sh         ### 
### USAGE:    sh ./audit.sh                              ###
############################################################ 
 
 
hostname=`uname -n`
dir=`dirname $0`


PATH=${PATH}:/usr/proc/bin; export PATH


#target=/tmp
target=.
cd $target


echo "Run audit part 1, results in $target/$hostname.audit1.log..."
sh $dir/audit1.sh > $hostname.audit1.$$.log 2>&1


echo "Create one gzipped tarball from .."
ls -al $hostname.audit[12]*log

echo "finished"
