#! /usr/bin/env bash

# This script is taken from:
# https://help.ubuntu.com/community/AutomaticSecurityUpdates#Using_cron_and_aptitude

# It "safely" automatically applies securtity updates.

echo "**************" >> /var/log/apt-security-updates
date >> /var/log/apt-security-updates
aptitude update >> /var/log/apt-security-updates
#aptitude safe-upgrade -o Aptitude::Delete-Unused=false --assume-yes --target-release `lsb_release -cs`-security >> /var/log/apt-security-updates
#Changed to just install all updates
apt-get -qy upgrade >> /var/log/apt-security-updates
echo "Security updates (if any) installed"

