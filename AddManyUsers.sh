#!/bin/bash
set -x

#################
# Script to add man users to the CEB GPU cluser
# Username, UID and expected from an input file
# Only the Username and UID are used.  GID is set to UID and SHELL is set to /sbin/nologin
#
# Input file format example
# nlmlhcnscanner:x:1521:1521:NLM LHC NSCANNER, CR:/export/home/nlmlhcnscanner:/bin/bash
#
# Author: Joseph Santoroski
# Created: June 5, 2018
#
# Revision History
# 20180601 - Fixed egrep and sed command so they would not match on simmilar user names. (JS)
#
#
##########

# Set a path 
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin:/usr/local/bin

# System dependent commands, files and variables
declare -r UNAME=`$(which uname)`
declare -r SUDOERS=/etc/sudoers 
declare -r PASSFILE=/etc/passwd
declare -r SHADOWFILE=/etc/shadow
declare -r GROUPFILE=/etc/group
declare -r EGREP=$(which egrep)
declare -r PASSWD=$(which passwd)
declare -r PWCONV=$(which pwconv)
declare -r MKDIR="$(which mkdir) -p"
declare -r ECHO="$(which echo)"
declare -r CHMOD=$(which chmod)
declare -r CHOWN=$(which chown)
declare -r SED=$(which sed)
declare -r ID=$(which id)
declare -r TEE="$(which tee) -a"
declare -r CAT=$(which cat)
declare -r DATE=`$(which date)`
declare -r HOST=`$(which hostname)`
declare -r SUDO_CMD=$(which sudo)
declare -r FIND=$(which find)
declare -r PS=$(which ps)
declare -r TAIL=$(which tail)
declare -r ADDUSER=$(which useradd)
declare -r GROUPADD=$(which groupadd)

# LogFile
declare -r LOG=/tmp/nlmlhcisg_AddMany.log

# Remove old log file
[ -e $LOG ] && rm -f $LOG

# echo enviroment for testing
env >> $LOG

# Default User, only for testing
_USER="testuser"
_UID="123456789"
_GID=$_UID
HOME="/home/testuser"
SHELL=$(which nologin)
INPUT_FILE="/dev/null"

# Parameters
if [ $# == 0 ]; then
	echo "Need input file with this format: nlmlhcnscanner:x:1521:1521:NLM LHC NSCANNER, CR:/export/home/nlmlhcnscanner:/bin/bash" >> $LOG
	exit 1
else
	INPUT_FILE=$@
fi

if [ -f $INPUT_FILE ]; then
	$ECHO "Input file " $INPUT_FILE " exist" >> $LOG
else
	$ECHO "Input file " $INPUT_FILE " does not exist" >> $LOG
	exit 1
fi

# Echo inputs to log for debugging
#echo "_USER, _UID, _GID, SHELL, HOME: "$_USER, $_UID, $_GID, $SHELL, HOME >> $LOG

# Determine OS type
if [[ "$UNAME" != "Linux" ]]
then
	echo "Need to run on Linux Distro" >> $LOG
	exit 1
fi

#Set up while loop
#Most of the inputs are not used, just _USER and _UID (_GID is set to _UID)
while IFS=":" read _USER _NAME _UID _GID _FULLNAME _OLDHOME _OLDSHELL; do
	echo $_USER $_NAME $_UID $_GID $_FULLNAME $_OLDHOME $_OLDSHELL >> $LOG
	if $EGREP "^$_USER:" /etc/passwd >/dev/null; then
		echo "$_USER exists!" >> $LOG
        else            
		HOME=/home/$_USER
		_GID=$_UID
    		echo "Creating user, group, home and shaow entries for: $_USER $_UID $_GID $SHELL" >> $LOG
    		# Make the user home directory, group id and user id.  Login shell is /usr/sbin/nologin
    		$GROUPADD --gid $_GID $_USER >> $LOG
    		$ADDUSER --home $HOME --shell $SHELL --uid $_UID --gid $_GID --password NP $_USER >> $LOG
    		$SED -i "s/^$_USER:.*/$_USER:NP:17683::::::/" $SHADOWFILE
    		$MKDIR $HOME >> $LOG
    		# Set ownerership and set file modes
    		$CHOWN -R $_USER:$_USER $HOME && $CHMOD -R 700 $HOME >> $LOG
    		/bin/ls -tal /home >> $LOG
        fi
done < "$INPUT_FILE"

exit 0


