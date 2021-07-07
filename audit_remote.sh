#!/bin/sh
#######################################################################
### audit_remote.sh                                                 ###
### Connect to a list of if machines, download the audit scripts,   ###
### run then, compress results and upload them then remove files    ###
### from remote servers.                                            ###
### - Adapt the server list "server1 server2" etc. below            ###
### - you'll need an SSH trust ot target systems                    ###
### - delete the "sudo" if not needed                               ###
#######################################################################

dir1="/tmp/aud"

for h in 192.168.w.x 134 192.168.y.z
 do
  echo "Connecting to $h `date`"
  ssh $h "mkdir $dir1 2>/dev/null; chmod 700 $dir1"
  scp -q audit.sh audit1.sh $h:/$dir1
  echo "Run audit `date` on $h"
  ssh  -t $h "PATH=${PATH}:/bin/:/usr/local/bin; cd $dir1; nice sudo ./audit.sh"
  scp -q "$h":"$dir1"/"*.tgz" .
  ssh $h "rm -f $dir1/*"

done
echo "Finished `date`"
