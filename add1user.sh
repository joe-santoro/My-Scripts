#!/bin/bash
#set -x

#################
# One time use script to add user to a system and the "wheel" group for sudo
# This script is intended to be run from BigFix
#
# Author: Joseph Santoroski
# Created: June 6, 2018
#
# Revision History
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
declare -r TAIL=$(which tail)
declare -r ADDUSER=$(which useradd)
declare -r GROUPADD=$(which groupadd)
declare -r USERMOD=$(which usermod)

# LogFile
declare -r LOG=/tmp/add1user.log

# Remove old log file
[ -e $LOG ] && rm -f $LOG

# One time use script, set _USER and UID here
_USER="jsantoroski"
_UID="643"
_GID=$_UID
HOME=/home/$_USER
SHELL=$(which bash)

# Echo inputs to log for debugging
$ECHO "_USER, _UID, _GID, SHELL, HOME: "$_USER, $_UID, $_GID, $SHELL, HOME >> $LOG

# Determine OS type
if [[ "$UNAME" != "Linux" ]]
then
	$ECHO "Need to run on Linux Distro" >> $LOG
	exit 1
fi

# Check if user exists in group file
$EGREP "^$_USER:" /etc/group >/dev/null
if [ $? -eq 0 ]; then
    $ECHO "$_USER already exists in group file" >> $LOG
    exit 1
fi

# Check if user exists in passwd file
$EGREP "^$_USER:" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
    $ECHO "$_USER already exists in passwd file" >> $LOG
    exit 1
else
    $ECHO "Creating user, group, home and shaow entries for: $_USER!" >> $LOG
    # Make the user home directory, group id and user id.  Login shell is /usr/sbin/nologin
    $GROUPADD --gid $_GID $_USER >> $LOG
    $ADDUSER --home $HOME --shell $SHELL --uid $_UID --gid $_GID --password NP $_USER >> $LOG
    $SED -i "s/^$_USER:.*/$_USER:NP:17683::::::/" $SHADOWFILE
    # Add to wheel group for sudo
    $ECHO $USERMOD -G $_USER,wheel $_USER >> $LOG
    $USERMOD -G $_USER,wheel $_USER >> $LOG
    $MKDIR $HOME >> $LOG
    # Set ownerership and set file modes
    $CHOWN -R $_USER:$_USER $HOME && $CHMOD -R 700 $HOME >> $LOG
    /bin/ls -tal /home >> $LOG
    $ECHO "sshd:130.14.117." >> /etc/hosts.allow
    $ECHO "sshd:[2607:f220:411:8117::0]/64" >> /etc/hosts.allow
fi

exit 0
