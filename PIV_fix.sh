#!/bin/bash
#Script used at NIH to correct a PIV login issue.  Possible a certificate chain issue
#

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

sudo defaults write /Library/Preferences/com.apple.security.revocation.plist fooset None
sudo defaults delete /Library/Preferences/com.apple.security.revocation.plist fooset
sudo defaults write /Library/Preferences/com.apple.security.revocation.plist CRLStyle None
sudo defaults write /Library/Preferences/com.apple.security.revocation.plist OCSPStyle None
#sudo defaults write /Library/Preferences/com.apple.security.revocation OCSPStyle -string None
#sudo defaults write /Library/Preferences/com.apple.security.revocation CRLStyle -string None
 
sudo /bin/rm -r /var/db/TokenCache/tokens/*
sudo /sbin/reboot
