#!/bin/bash
# Grep the iptables files to look for abusers.  Generate iptables code to be copy/pasted into /etc/sysconfig/iptables
# run as root (JSS)

grep DROP /var/log/iptables.log |  awk '{ print $9 }' | sort | uniq | sed s/SRC=//g | awk '{ printf "-A INPUT -s %s -j DROP\n", $1 }' > /tmp/iptables_drops.txt

