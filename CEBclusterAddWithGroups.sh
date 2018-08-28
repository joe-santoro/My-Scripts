#!/bin/bash
set -x 

# 
#// Enter your action script here
#action parameter query "USERNAME" with description "Please enter USERNAME"
#action parameter query "UID" with description "Please enter User ID (UID)"
#action parameter query "GROUPS" with description "Enter group(s), each group is comma separated with NO space"
# 
#delete __createfile
#createfile until _EOF
#!/bin/bash
set -x
 
#################
# Name: CEBclusterAddWithGroups.sh
# Script to add users to the CEB GPU cluser
# Parameters: Username, User ID
# This script is intended to be run from BigFix
#
# Author: Joseph Santoroski
# Created: June 1, 2018
# 
# Revision History
# 20180601 - Fixed egrep and sed command so they would not match on simmilar user names. (JS)
# 20180606 - Check for user in group before adding (JS)
# 20180801 - Added group support
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
declare -r USERMOD=$(which usermod)
 
# LogFile
declare -r LOG=/tmp/CEBclusterAddWithGroups.log
 
# Remove old log file
[ -e $LOG ] && rm -f $LOG
 
# echo enviroment for testing
env >> $LOG
 
# Default User, only for testing
_USER="testuser"
_UID="123456789"
_GID=$_UID
_GROUPS="staff"
HOME="/home/testuser"
SHELL=$(which nologin)
 
# Parameters
if [ $# -gt 1 ]; then
	_USER=$1
        _UID=$2
        _GID=$2
        HOME=/home/$_USER
	if [ ! -z $3 ]; then
		_GROUPS=$3
	fi
else
        $ECHO "Need parameters Username and UID" >> $LOG
        exit 1
fi
 
# Echo inputs to log for debugging
$ECHO "_USER, _UID, _GID, _GROUPS, SHELL, HOME: "$_USER, $_UID, $_GID, $_GROUPS, $SHELL, HOME >> $LOG
 
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

    # Create Home and set ownerership and file modes
    $MKDIR $HOME >> $LOG
    $CHOWN -R $_USER:$_USER $HOME && $CHMOD -R 700 $HOME >> $LOG
    /bin/ls -tal /home >> $LOG

    #Add user to groups
    if [ ! -z $3 ]; then
	$ECHO "Calling usermod -a -G " $_GROUPS " " $_USER >> $LOG
	$USERMOD -a -G $_GROUPS $_USER >> $LOG
    fi
fi
exit 0
#_EOF
# 
#// move __createfile cebuser.sh
#// waithidden /bin/sh cebuser.sh "{parameter "USERNAME" as trimmed string}" "{parameter "UID" as trimmed string}"
#//wait chmod 555 __createfile
#//wait /bin/sh __createfile "{parameter "USERNAME" as trimmed string}" "{parameter "UID" as trimmed string}"
#//delete __createfile
# 
#wait chmod 555 "{(client folder of current site as string) & "/__createfile"}"
#wait "{(client folder of current site as string) & "/__createfile"}" "{parameter "USERNAME" as trimmed string}" "{parameter "UID" as trimmed string}" "{parameter "GROUPS" as trimmed string}"
#delete __createfile
# 

