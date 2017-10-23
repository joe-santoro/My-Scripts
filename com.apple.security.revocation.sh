#!/bin/sh
# Reset the security revocation setting back to default after the PIV fix
sudo defaults write /Library/Preferences/com.apple.security.revocation CRLStyle -string BestAttempt
sudo defaults write /Library/Preferences/com.apple.security.revocation CRLSufficientPerCert -bool YES
sudo defaults write /Library/Preferences/com.apple.security.revocation OCSPStyle -string BestAttempt
sudo defaults write /Library/Preferences/com.apple.security.revocation OCSPSufficientPerCert -bool YES
sudo defaults write /Library/Preferences/com.apple.security.revocation RevocationFirst -string OCSP
