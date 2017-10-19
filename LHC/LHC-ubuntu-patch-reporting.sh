#!/bin/bash
# Name: LHC-ubuntu-patch-reporting.sh
# Author: Joe Santoroski
# Last Modified: 19Oct2017
# Version 1.0.1
# Description:  This scripts provided patch reporting for the LHC division at NLM
#   The current patch of all installed packages are reported
#   Also any patches that are outstanding are reported separately
#   Security related patches are prefixed with "#SEC=" and non-security ones with "#SW="
#   The name, IP, kernel ver, and date the report was run are also reported.
# Note: This scripts will not apply any patches.
#
# run this to installed required package:
# sudo apt-get install tofrodos
# sudo apt install apt-show-versions

# Get release name
. /etc/lsb-release
SEC="-security"
DISTRIB_SEC="${DISTRIB_CODENAME}-security"
#echo $DISTRIB_SEC

# The DISTRIB_CODENAME comes from the /etc/lsb-release.  It's the code name for this version of ubuntu
# The DISTRIB_SEC is the release name plus "-security".  
# These two strings will be used to distinguish between security and non-security releated updates. 
#echo $DISTRIB_CODENAME
#echo $DISTRIB_SEC

OUTFILE=sw_list.txt
UPDATEFILE=sec_pkg.txt
IPADD=`/sbin/ifconfig | sed '/Bcast/!d' | awk '{print $2}'| awk '{print $2}' FS=":"`

cd /tmp

# Be sure the apt database is current
apt-get update

# Get listing of all packges on the system using the dpkg-query command
echo "#NAME=" `hostname` | todos > $OUTFILE 
echo "#IP=" $IPADD | todos >> $OUTFILE
echo "#DATE=" `date` | todos >> $OUTFILE
echo "#BEGIN" | todos >> $OUTFILE
dpkg-query -l | todos >> $OUTFILE
echo "#END" | todos >> $OUTFILE

# Get packages that can be updated and seperate into "security" patches
# and "non-security" patches.
echo "#NAME=" `hostname` | todos > $UPDATEFILE
echo "#IP=" $IPADD | todos >> $UPDATEFILE
echo "#DATE=" `date` | todos >> $UPDATEFILE
echo "Kernel Version: " `uname -r` | todos  >> $UPDATEFILE
echo `uname -a` | todos >> $UPDATEFILE
echo "List of packages to be updated on: " `hostname` | todos >> $UPDATEFILE
echo "#BEGIN" | todos >> $UPDATEFILE

# Filter out and print only security related updated.
apt-show-versions -u | grep $DISTRIB_SEC | awk '{print "#SEC="$0}' | todos >> $UPDATEFILE

# Filter out and print only non-security related updated.
apt-show-versions -u | egrep -v $DISTRIB_SEC | awk '{print "#SW="$0}' | todos >> $UPDATEFILE
echo "#END" | todos >> $UPDATEFILE

# Optional email results
#(echo From: "User At DomainDotCom <user@domain.com>" ; echo Subject: Tahoe packags ; uuencode $OUTFILE $OUTFILE ; uuencode $UPDATEFILE $UPDATEFILE ) | sendmail user@domain.com 

# Keep the apt cache clean
apt-get autoclean

# END (JS)

