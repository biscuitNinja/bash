#!/bin/sh

#
# A simple bash script that uses curl to create a pfSense webGUI session and 
# then uses that session to backup pfSense config
#

#set -vx


firewallBackupUrl="https://abus.bikeshed.internal/diag_backup.php"
usr="backup"
pwd="loginPassword"
encPwd="cofigurationBackupEncryptionPassword"
backupFolder="/zfs/biz/it/configuration/abus/"

csrfToken=$(curl -s -k -b ~/cookieJar -c ~/cookieJar $firewallBackupUrl | sed -n 's/.*name=.__csrf_magic.\s\+value="\([^"]\+\)".*/\1/p' )

if [ -z "$csrfToken" ] ; then
        echo "Failed to get CSRF Token" 
        exit 1
fi

curl -s -k -b ~/cookieJar -c ~/cookieJar --data "login=Login&usernamefld=${usr}&passwordfld=${pwd}&__csrf_magic=$csrfToken" $firewallBackupUrl

#Download Backup
curl -s -k -b ~/cookieJar -o ${backupFolder}config-abus.bikeshed.internal-`date +%Y%m%d%H%M%S`.xml --data "Submit=Download configuration&encrypt=on&encrypt_password=${encPwd}&encrypt_passconf=${encPwd}" https://abus.bikeshed.internal/diag_backup.php

rm -rf ~/cookieJar
find ${backupFolder}/* -ctime +60 -delete
