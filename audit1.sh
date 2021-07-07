#!/bin/sh 
################################################################################
### audit1.sh                                                                ###
###                                                                          ###
### This script runs with root permisions to generate an off line text file  ###
### to act as a base line and for offline analysis.                          ###
################################################################################

VERSION="Audit1.sh: V0.8"

### Debugging ###
#set -x 
### Should /etc/shadow and startup file permissions also be included? ###
#EXTENDED='0'
EXTENDED='1'
### Expression used by egrep to ignore comments ###
### egrep is not as powerful as perl, and differs a bit between platforms. ###
comments='^#|^ +#|^$|^ $'
#comments='^#|^    #|^$|^ $'
#comments='^#|^$|^ +$'
### Output results to screen also? ###
f=$0.$$.out 
VERBOSE='1'
#VERBOSE_SUM='1'
FILE='0'

### ---------- OS Settings ---------- ###
os=`uname -s`
hw=`uname -m`
if [ "$os" = "Linux" ]
 then
  #echo $os
  echo='/bin/echo -e'
  #ps='ps -auwx'
  #ps='ps auwx'
  ps='ps -ef'
  proc1='/bin/ps -e -o comm '
  fstab='/etc/fstab'
  shares='/etc/exports'
  lsof='lsof -i'
  mount='mount'
  PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/lib/saint/bin:/opt/postfix:/usr/lib/java/jre/bin
  aliases='/etc/aliases'
  key_progs='/usr/bin/passwd /bin/login /bin/ps /bin/netstat'
  snmp='/etc/snmp/snmpd.conf'
  crontab='crontab -u root -l'
  ntp='/etc/ntp.conf'
fi

### ---------- common programs ---------- ###
sum='/usr/bin/sum' 

### ---------- functions ---------- ###
check_err () {
 if [ "$*" != "0" ]
  then
   $echo "SCRIPT $0 ABORTED: error." >>$f 2>&1
   send_results
  exit 1
 fi
}
run () {
 if [ $FILE = "1" ]
  then
   $echo "Running command: $*" >>$f
 fi
 if [ $VERBOSE = "1" ]
  then
   $echo "Running command: $*"
 fi
 if [ $FILE = "1" ]
  then
   $*    >> $f
  else
   $*
 fi
}

### ---------- Start of script audits ---------- ###

### ---------- Uncomment these lines if you want to run this locally ---------- ### 
#$echo "This system will be analysed and the results written to $f." 
#$echo "Press Control-C to abort, or any key to continue.." 
#read input 

$echo "###############################################"
$echo "AUDIT SCRIPT:$VERSION"
$echo "###############################################"
date
$echo " "

### ---------- What OS release are we running? ---------- ###
run uname -a
if   [ "$os" = "Linux" ]
 then
  cat /etc/lsb-release 2>/dev/null
  cat /etc/redhat-release  2>/dev/null
  cat /etc/oracle-release 2>/dev/null
  cat /etc/SuSE-release 2>/dev/null
fi
$echo " "
$echo "###############################################"
$echo "Logged on users:"
$echo "###############################################"
w
$echo " "
$echo "###############################################"
$echo "Account Information:"
$echo "###############################################"
$echo " "
$echo "### Acounts on System ###"
$echo "Number of accounts `wc -l /etc/passwd`"

$echo "\n### Accounts with UID=0: ###"
$echo `awk -F: '{if ($3=="0") print $1}' /etc/passwd`

$echo "\### nNIS(+)/YP accounts: ###"
grep '^+' /etc/passwd /etc/group
ypcat passwd 2>/dev/null
niscat passwd 2>/dev/null

$echo "\n### Accounts with no password: ###"
if [ -f /etc/shadow ]
 then
  $echo `awk -F: '{if ($2=="") print $1}' /etc/shadow`
 else
  $echo `awk -F: '{if ($2=="") print $1}' /etc/passwd`
fi

$echo "\n### Accounts with passwords (not blocked or empty) ###"
$echo `awk -F: '{if (($2!="*") && ($2!="") && ($2!="!") && ($2!="!!") && ($2!="NP") && ($2!="*LK*")) print $1}' /etc/passwd`

$echo "\n### Password settings: ###"
$echo "/etc/pam.d/passwd :"
egrep -v "$comments" /etc/pam.d/passwd
pwck -r
grpck -r

$echo "\n### Home directory SSH trust permissions: (watch out for world/group writeable) ###"
for h in `awk -F: '{print $6}' /etc/passwd | uniq`
 do
  ls -ald $h
 if [ -f $h/.ssh/authorized_keys ]
  then
   ls -ald $h/.ssh/authorized_keys
   cat $h/.ssh/authorized_keys
 fi
done

$echo "\n### sudo: /etc/sudoers... ###"
egrep -v "$comments" /etc/sudoers 2>/dev/null

$echo "\n### Console security... ###"
$echo "root is allowed to logon to the following (/etc/securetty) -"
egrep -v "$comments" /etc/securetty 2>/dev/null
grep securetty /etc/pam.d/login 2>/dev/null
grep PermitRootLogin /etc/ssh/sshd_config 2>/dev/null
$echo " "

$echo "###############################################"
$echo "System Security & Config Settings"
$echo "###############################################"
if   [ "$os" = "Linux" ]
 then
  $echo "\n### Linux security settings: ###"
  files="/etc/security/* /etc/ssh/sshd_config"
  for f in $files
   do
    if [ -f $f ]
     then
      $echo "\n### Linux Security config... $f .. ###"
      egrep -v "$comments" $f
    fi
   done

$echo "\n### Linux: kernel parameters -- ###"
  for f in net.ipv4.icmp_echo_ignore_all net.ipv4.icmp_echo_ignore_broadcasts net.ipv4.conf.all.accept_source_route net.ipv4.conf.all.send_redirects net.ipv4.ip_forward net.ipv4.conf.all.forwarding net.ipv4.conf.all.mc_forwarding net.ipv4.conf.all.rp_filter net.ipv4.ip_always_defrag net.ipv4.conf.all.log_martians
   do
    sysctl $f 2>/dev/null
   done

#$echo "\n### Linux: kernel modules (modprobe -c) ###"
#  run modprobe -c
#fi
$echo "\n### Disks & mount options ###"
$echo "Are any disks nearly full, are partitions well allocated?"
$echo "Are options like ro,logging,nosuid,size used?"
$echo " "
run df -k
$echo " "
run $mount
run free -m

$echo "\n### files with a .perm of 2000 or 4000 ###"
$echo "### and the last time it was modified ###"
run find / -type f \( -perm -4000 -o -perm -2000 \) -exec stat -c '%n : %y' {} \; 2>/dev/null

$echo "\n### Processes ###" 
$echo "Are any unexpected processes running, are too many running"
$echo "are they running as root?"
$echo " " 
run $ps

$echo "\n### Is lsof installed? We can list open files, device, ports ###"
which lsof 2>/dev/null
$lsof
$echo "\n### Run a checksum/hash on key binary files, it might help us ###"
$echo "### detect root kits, or serve as a reference for future audits. ###"
for f in $key_progs
 do
  $echo "Running 'sum' and 'md5' on $f ..."
  $sum $f 
  md5 $f 2>/dev/null
done

$echo "\n### Networks ###"
$echo "Interfaces:"
ifconfig -a
$echo "\nInterface statistics:"
netstat -i
$echo "\nRouting:"
netstat -rn
$echo "\nNetwork connections - current:"
netstat -a

$echo "\n### Inetd services ###"
$echo "Checking for inetd process.."
$ps | grep inetd
if [ -f /etc/inetd.conf ]
 then
  echo "Checking /etc/inetd.conf.."
  egrep -v "$comments" /etc/inetd.conf
fi
if [ -f /etc/xinetd.conf ]
 then
  echo "Checking /etc/xinetd.conf.."
  egrep -v "$comments" /etc/xinetd.conf
  ls -l /etc/xinetd.d
  echo "Checking for enabled services in xinetd.."
  egrep "disable.*no"  /etc/xinetd.d/*
fi

$echo "\n### TCP Wrappers, /etc/hosts.allow: ###"
egrep -v "$comments" /etc/hosts.allow   2>/dev/null

$echo "\n### TCP Wrappers, /etc/hosts.deny: ###"
egrep -v "$comments" /etc/hosts.deny    2>/dev/null

$echo "\n### ftp settings ###"
$echo "/etc/shells:"
egrep -v "$comments" /etc/shells    2>/dev/null
$echo "\n/etc/ftpusers:"
egrep -v "$comments" /etc/ftpusers  2>/dev/null
$echo "\nvsftpd.conf:"
egrep -v "$comments" /etc/vsftpd.conf  2>/dev/null
egrep -v "$comments" /etc/vsftpd/vsftpd.conf  2>/dev/null
if [ -f /etc/vsftpd.chroot_list ]
 then
  cat /etc/vsftpd.chroot_list
fi

$echo "\n### Inetd.conf contents relevant to FTP: ###"
if [ -f /etc/inetd.conf ]
 then
  egrep ftpd /etc/inetd.conf
fi
if [ -f /etc/xinetd.conf ]
 then
  echo "Checking /etc/xinetd.d/*ftp* .."
  ls -l /etc/xinetd.d/*ftp*
  cat /etc/xinetd.d/*ftp*
fi

$echo "\n### NTP - network time protocol ###"
$ps | grep ntpd
$echo "ntp config - $ntp:"
egrep -v "$comments" $ntp 2>/dev/null

$echo "\n### /dev/random ###"
ls -l /dev/random 2>/dev/null

$echo "\n### SSH ###"
$echo "# SSH daemon version #"
$ps | grep sshd
process=`${proc1} | sort | uniq | grep sshd`
[ $? = 0 ] && $process -invalid 2>&1|head -2|tail -1;
$echo "# SSH client version #"
ssh -V 2>&1
run whereis ssh
$echo "# Active SSHD config: #"
files="/etc /etc/ssh /usr/local/etc /opt/openssh/etc /opt/ssh/etc"
for f in $files
 do
  if [ -f $f/sshd_config ]
 then
    echo "ssh config... $f/sshd_config .."
    egrep -v "$comments" $f/sshd_config
  fi
done

$echo "\n### RPC ###"
rpcinfo -p localhost  2>/dev/null

$echo "\n### NIS+ ###"
nisls -l 2>/dev/null

$echo "\n### NFS sharing ###"
egrep -v "$comments" $shares 2>/dev/null
showmount -e          2>/dev/null
showmount -a          2>/dev/null

$echo "\n### NFS client ###"
egrep -v "$comments" $fstab | grep nfs
$mount | grep nfs

$echo "\n### X11: xauth ###"
echo "DISPLAY = `echo $DISPLAY`"
xauth list
# xhost blocks sometime (when X11 running and no display?)
#xhost
echo "ls /etc/X*.hosts : `ls /etc/X*.hosts 2>/dev/null`"

$echo "\n### hosts ###"
$echo "/etc/nsswitch.conf - hosts entry:"
grep hosts /etc/nsswitch.conf
$echo "/etc/resolv.conf :"
egrep -v "$comments" /etc/resolv.conf
$echo "/etc/hosts :"
egrep -v "$comments" /etc/hosts

$echo "\n### SNMP , config $snmp ###"
if [ -f $snmp ]
 then
  egrep -v "$comments" $snmp
fi
$ps | grep snmp

$echo "\n### Cron Info ###"
$echo "\nroot cron:"
$crontab | egrep -v "$comments"
$echo "\n"
$echo "/etc/cron.d/ :"
ls -l /etc/cron.d/
## TBD: show all files in cron.d ?
cat /etc/cron.d/cron.allow 2>/dev/null
cat /etc/cron.d/at.allow   2>/dev/null
$echo "cron.deny:"
cat /etc/cron.d/cron.deny   2>/dev/null
$echo "at.deny:"
cat   /etc/cron.d/at.deny   2>/dev/null

$echo "\n### Environment variables and PATH: ###"
$echo "### (check especially for '.' in the root PATH) ###"
env
echo $PATH

$echo "\n### root interactive umask (should be at least 022, or better 027 or 077): ###"
umask

$echo "\n### Searching for Daemon umasks in /sbin/init.d/*/* (to see if daemons start securely): ###"
egrep -v "$comments" /sbin/init.d/*  2>/dev/null | grep umask
egrep -v "$comments" /sbin/init.d/*/* 2>/dev/null | grep umask
egrep -v "$comments" /etc/init.d/*   2>/dev/null | grep umask
egrep -v "$comments" /etc/init.d/*/* 2>/dev/null | grep umask

$echo "\n"
date

$echo "\n### Diagnostic messages (dmesg) ###"
dmesg|egrep -v "MARK"| tail -50

$echo "\n### LOGS ###"
$echo "\n### list files in /var/adm /var/log/* ###"
# list dirs and ignore dirs not ther (i.e. errors)
ls -l /var/log/* /var/adm/*  2>/dev/null
ls -l /var/log/*/*           2>/dev/null
# ignore for now: vold.log (23.2.03)
logs="sulog messages loginlog aculog shutdownlog rbootd.log vtdaemonlog system.log shutdownlog snmpd.log automount.log"
$echo "\nChecking /var/adm $logs"
for log in $logs
 do
  if [ -s /var/adm/$log ]
 then
    $echo "\nTail -50 of /var/adm/$log..."
    tail -50 /var/adm/$log |egrep -v "MARK" 2>/dev/null
  fi
done
logs="messages xferlog ipflog weekly.out monthly.out adduser secure ftpd log.nmb log.smb samba.log httpd.access_log httpd.error_log mail warn Config.bootup access_log boot.msg samhain_log yule_log"
$echo "\nChecking $logs"
for log in $logs
 do
  if [ -s /var/log/$log ]
 then
    $echo "\nTail -50 of /var/log/$log..."
    tail -50 /var/log/$log |egrep -v "MARK" 2>/dev/null
  fi
done
logs="syslog lprlog authlog maillog kernlog daemonlog alertlog newslog local0log local2log local5log sshlog cronlog"
for log in $logs
 do
  if [ -s /var/log/$log ]
 then
    $echo "\nTail -50 of /var/log/$log..."
    tail -50 /var/log/$log |egrep -v "MARK" 2>/dev/null
  fi
done

$echo "\n### Last 50 logins ###"
run last |head -50
run faillog -a |head -50  2>/dev/null
# logs: C2, Sulog, loginlog, cron log, accounting, /etc/utmp, utmpx, wtmp,
#  wtmpx, lastlog, SAR logs, NIS+ transaction log, ...).
#  Are syslog messages centralised on a specially configured log server?
#  Are all priorities/services logged?
#  Are log files protected (file permissions)?
#  Are they automatically pruned / compressed? How often?

$echo "\n### Patches for $os ###"
$echo "\n Auto start daemons:"
run systemctl list-units --type service
$echo "\n Package DB:"
run apt-get check
run apt-get update -s
run apt-get upgrade -s
$echo "\n### Checking Samba ###"
$ps | grep smbd | egrep -v "grep smbd"
process=`${proc1} | sort | uniq | grep smbd`
[ $? = 0 ] && echo "Samba `$process -V`"
files="/var/log/samba /var/log.smb /var/log/log.smb"
for f in $files
 do
  if [ -f $f ]
 then
    echo "\nsamba logs $f .."
    ls -l $f
  fi
done
files="/usr/local/samba/lib/smb.conf /etc/samba/smb.conf"
for f in $files
 do
  if [ -f $f ]
 then
    echo "\nsamba config $f .."
    # Samba can have comments with ';'
    egrep -v '^ *#|^$|^;' $f
  fi
done

$echo "\n### Checking BIND/Named ###"
$ps | grep dnsmasq | egrep -v "grep dnsmasq"
process=`${proc1} | sort | uniq | grep dnsmasq`
[ $? = 0 ] && $process -v 2>&1
$ps | grep named | egrep -v "grep named"
process=`${proc1} | sort | uniq | grep named`
[ $? = 0 ] && $process -v
for f in `whereis named| awk -F: '{print $2}'`
 do ls -l $f
done
files="/etc/named.conf /usr/local/etc/named.conf /etc/dnsmasq.conf"
for f in $files
 do
  if [ -f $f ]
 then
    $echo "\nDNS config... $f .."
    egrep -v "$comments|^//|^/\*|^ \*" $f
  fi
done

$echo "\n### Checking DHCPD ###"
$ps | grep dhcpd| egrep -v "grep dhcpd"
for f in `whereis dhcpd| awk -F: '{print $2}'`
 do ls -l $f
done
# Version
process=`${proc1} | sort | uniq | grep dhcpd`
[ $? = 0 ] && $process -V 2>&1|head -1
files="/etc /opt/ISC_DHCP /etc /etc/dhcpd"
for f in $files
 do
  if [ -f $f/dhcpd.conf ]
 then
    $echo "\ndhcp config... $f .."
    egrep -v "$comments" $f/dhcpd.conf
  fi
done

$echo "\n### Checking LDAP ###"
$ps | grep slapd| egrep -v "grep slapd"
for f in `whereis slapd| awk -F: '{print $2}'`
 do ls -l $f
done
# Version
files="/var/log/openldap/logfile"
for f in $files
 do
  if [ -f $f ]
 then
    #$echo "\nhttpd logs... $f .."
    run tail -50 $f
  fi
done
files="/opt/openldap/etc"
for f in $files
 do
  if [ -d $f ]
 then
    $echo "\nLDAP config dir... $f .."
  fi
done

$echo "\n### Checking Apache ###"
$ps | grep httpsd| egrep -v "grep httpsd"
for f in `whereis httpsd| awk -F: '{print $2}'`
 do ls -l $f
done
# Version http with SSL
process=`${proc1} | sort | uniq | grep httpsd`
[ $? = 0 ] && $process -v
$ps | grep httpd| egrep -v "grep httpd"
for f in `whereis httpd| awk -F: '{print $2}'`
 do ls -l $f
done
# Version httpd
process=`${proc1} | sort | uniq | grep httpd`
[ $? = 0 ] && $process -v
## Apache: config
files="/usr/local/apache/conf /usr/local/apache2/conf /opt/apache/conf /etc/httpd /etc/httpd/conf /etc/apache /etc/apache2 /var/www/conf /opt/portal/apache/conf"
for f in $files
 do
  if [ -f $f/httpd.conf ]
 then
    $echo "\nhttpd config... $f .."
    egrep -v "$comments" $f/httpd.conf
  fi
  if [ -f $f/httpsd.conf ]
 then
    $echo "\nhttpsd config... $f .."
    egrep -v "$comments" $f/httpsd.conf
  fi
done
## Apache2
if [ -d /etc/apache2 ]
 then
  cd /etc/apache2
  files=`ls *conf */*conf`
  for f in $files
   do
    $echo "\nApache2: $f ..."
    egrep -v "$comments" $f
 done
fi
## Apache: error logs
files="/usr/local/apache /usr/local/apache2 /opt/apache /var/www /opt/portal/apache"
for f in $files/logs/error_log
 do
  if [ -f $f ]
 then
    #$echo "\nhttpd logs... $f .."
    run tail -50 $f
  fi
done
files="/var/log/httpd/error_log /var/log/apache2/error_log /var/log/apache/httpsd_error_log /var/log/apache/httpd_error_log"
for f in $files
 do
  if [ -f $f ]
 then
    #$echo "\nhttpd logs... $f .."
    run tail -50 $f
  fi
done
files="/usr/local/apache /usr/local/httpd /usr/local/apache2 /opt/apache /var/www /opt/portal/apache /srv/www "
for f in $files
 do
  if [ -d $f/cgi-bin ]
 then
    $echo "\ncgi scripts in $f/cgi-bin .."
    ls -al $f/cgi-bin
  fi
done

$echo "\n### Checking syslog config ###"
$echo "loghost alias in /etc/hosts:"
grep loghost /etc/hosts
$echo "\nChecking /etc/syslog.conf .."
egrep  -v "$comments" /etc/syslog.conf      2>/dev/null
$echo "\nChecking /etc/syslog-ng.conf .."
egrep  -v "$comments" /etc/syslog-ng.conf      2>/dev/null
egrep  -v "$comments" /etc/syslog-ng/syslog-ng.conf      2>/dev/null
egrep  -v "$comments" /usr/local/etc/syslog-ng.conf      2>/dev/null

$echo "\n### Java version ###"
if java -version | grep -q "java version"
then
  java -version 2>&1
else
  echo "Java NOT installed!"
fi

$echo "\n### List of mail boxes ###"
ls -lt /var/mail/*

$echo "\n### Checking sendmail email config ###"
$echo "Sendmail process:"
$ps | grep sendmail | egrep -v "grep sendmail"
process=`${proc1} | sort | uniq | grep sendmail`
[ $? = 0 ] && echo "Sendmail `what $process |egrep 'SunOS| main.c'`"
$echo "\nmailhost alias in /etc/hosts:"
grep mailhost /etc/hosts
$echo "\nChecking $aliases for programs.."
egrep -v "$comments" $aliases | grep  '|'
$echo "\nChecking $aliases for root.."
egrep '^root' $aliases
$echo "\nsendmail.cf:"
egrep -v '^#|^$|^R|^S|^H' /etc/sendmail.cf 2>/dev/null
egrep -v '^#|^$|^R|^S|^H' /etc/mail/sendmail.cf 2>/dev/null
$echo "\nChecking /etc/mail/relay-domains .."
egrep  -v "$comments" /etc/mail/relay-domains 2>/dev/null

$echo "\n### Checking SMTPD/Postfix ###"
$ps | grep smtpd | egrep -v "grep smtpd"
if [ `whereis postfix|wc -w` -gt 1 ]
 then
  # postfix is installed
  $echo "\nPostfix non default settings:"
  postconf -n 2>&1
  for f in `whereis postfix| awk -F: '{print $2}'`
   do ls -ld $f
  done
  for f in `whereis postmap| awk -F: '{print $2}'`
    do ls -ld $f
  done
  $echo "\n"
  postfix -v -v check 2>&1
  $echo "\n"
files="/etc/postfix/main.cf /etc/postfix/master.cf /etc/postfix/canonical /etc/postfix/recipient_canonical /etc/postfix/access /etc/postfix/virtual /etc/postfix/transport /etc/postfix/relocated /usr/local/postfix/etc/main.cf /usr/local/postfix/etc/master.cf /usr/local/postfix/etc/canonical /usr/local/postfix/etc/recipient_canonical /usr/local/postfix/etc/access /usr/local/postfix/etc/virtual /usr/local/postfix/etc/transport /usr/local/postfix/etc/relocated  "
  for f in $files
   do
    if [ -f $f ]
   then
      $echo "\nPOSTFIX config $f..."
      egrep -v "$comments" $f
    fi
  done
fi
$echo "\nChecking mail queue.."
mailq

if [ $EXTENDED = "1" ]
 then
  $echo "\n### Extended audit: add shadow file ###"
  cat /etc/shadow

$echo "\n### Extended audit: permissions of startup files ###"
for d in /etc/init.d /etc/rc2.d /etc/rc3.d /etc/rc.d
 do
  if [ -d $d ]
 then
   run ls -alR $d
   fi
  done
fi

$echo "\n### Checking mysql ###"
$ps | grep mysqld| egrep -v "grep mysqld"
for f in `whereis mysqld| awk -F: '{print $2}'`
 do ls -l $f
 done
# Version
process=`${proc1} | sort | uniq | grep mysqld`
[ $? = 0 ] && $process -V 2>&1|head -1
files="/etc/my.cnf /etc/mysql/my.cnf"
for f in $files
 do
  if [ -f $f ]
 then
   $echo "Mysql config $f .."
   egrep  -v "$comments" $f 2>/dev/null
  fi
done
files="/usr/local/mysql/data/mysqld.log"
for f in $files
 do
  if [ -f $f ]
 then
   $echo "Mysql logs tail -50 $f .."
   tail -50 $f | egrep  -v "$comments" 2>/dev/null
  fi
done
files="/usr/local/mysql/data /mysqldata"
for f in $files
 do
  if [ -d $f ]
 then
   $echo "Mysql data directories $f .."
   ls -al $f/* 2>/dev/null
  fi
done

$echo " "
date

$echo "\n###############################################"
$echo "Done with Audit"
$echo "###############################################"
