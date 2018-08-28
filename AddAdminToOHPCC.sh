#!/bin/bash
set -x

#################
# Name: AddAdminToOHPCC.sh
# Custom script to add several admin for OHPCC Linux machines.
# Users are add to the sudoers file via one of the SED edits to /etc/sudoers
# Tested on Ubuntu should work on other Linux distros
#
# Place username in the script below
# Only the Username and UID are used.  
#
# Input file format example (Entries from NIS are acceptable)
# nlmlhcnscanner:x:1521:1521:NLM LHC NSCANNER, CR:/export/home/nlmlhcnscanner:/bin/bash
#
# If the user is already in /etc/passwd that user is skipped
#
# Logfile: AddAdminToOHPCC.log
# Check logfile after running to see which users were added or skipped.

# Author: Joseph Santoroski
# Created: August 13, 2018
#
# Revision History
# 20180601 - Fixed egrep and sed command so they would not match on simmilar user names. (JS)
# 20180619 - Added additional notes to the description, changed some logging messages (JS)
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
declare -r USERMOD=$(which usermod)

# LogFile
declare -r LOG=/tmp/AddAdminToOHPCC.log

# Input File
INPUT_FILE="/tmp/admins.$$.txt"

# Remove old log file
[ -e $LOG ] && rm -f $LOG

# echo enviroment for testing
env >> $LOG

#########
# Add Users Here 
cat << __EOF > $INPUT_FILE
jochow:x:355:1523::/home/jochow:/bin/bash
kushnirm:x:478:1524::/home/kushnirm:/bin/bash
lneve:x:21255:21255::/home/lneve:/bin/bash
ozeryanv:x:21252:21252::/home/ozeryanv:/bin/bash
bhangdiavd:x:457:457::/home/bhangdiavd:/bin/bash
__EOF
# End of users list
###

# Default User, only for testing
_USER="testuser"
_UID="123456789"
_GID=$_UID
HOME="/home/testuser"
#SHELL=$(which nologin)
SHELL=$(which bash)

if [ -f $INPUT_FILE ]; then
	$ECHO "Input file " $INPUT_FILE " exist" >> $LOG
else
	$ECHO "*** Input file " $INPUT_FILE " does not exist, exiting..." >> $LOG
	exit 1
fi

# Echo inputs to log for debugging
#echo "_USER, _UID, _GID, SHELL, HOME: "$_USER, $_UID, $_GID, $SHELL, HOME >> $LOG

# Determine OS type
if [[ "$UNAME" != "Linux" ]]
then
	echo "*** Need to run on Linux Distro, exiting" >> $LOG
	exit 1
fi

#echo Input_File to log
cat $INPUT_FILE >> $LOG

#Set up while loop
#Most of the inputs are not used, just _USER and _UID (_GID is set to _UID)
while IFS=":" read _USER _NAME _UID _GID _FULLNAME _OLDHOME _OLDSHELL; do
	echo $_USER $_NAME $_UID $_GID $_FULLNAME $_OLDHOME $_OLDSHELL >> $LOG
	if $EGREP "^$_USER:" /etc/passwd >/dev/null; then
		echo "*** $_USER exists, skipping!" >> $LOG
        else            
		HOME=/home/$_USER
		#_GID=$_UID
    		echo "Creating user, group, home and shaow entries for: $_USER $_UID $_GID $SHELL" >> $LOG
    		# Make the user home directory, group id and user id.  Login shell is /bin/bash
    		$GROUPADD --gid $_GID $_USER >> $LOG
    		$ADDUSER --home $HOME --shell $SHELL --uid $_UID --gid $_GID --password NP $_USER >> $LOG
		# Add user to wheel group
		$ECHO "Calling usermod -a -G wheel " $_USER >> $LOG
		$USERMOD -a -G wheel $_USER >> $LOG
		# Set password to work with RSA
    		$SED -i "s/^$_USER:.*/$_USER:NP:17683::::::/" $SHADOWFILE
    		# Make Home dir and Set ownerership and set file modes
    		$MKDIR $HOME >> $LOG
    		$CHOWN -R $_USER:$_USER $HOME && $CHMOD -R 700 $HOME >> $LOG
    		/bin/ls -tal /home >> $LOG
        fi
done < "$INPUT_FILE"

exit 0

