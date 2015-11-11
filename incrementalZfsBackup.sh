#!/bin/bash

# Exit codes:
# 110   remoteDestination is not online
# 120   failed to take snapshot
# 130   failed to send snapshot
# 140   failed to destroy snapshot

storagePool="bikeshed"
remoteDestination=mundo.bikeshed.internal
remoteUser=zfsbackup
identifyFile=/root/.ssh/id_rsa_zfsbackup_bikeshed_mundo.bikeshed.internal

for ((i=1;i<=20;i++)) ; do
        nc -z $remoteDestination 22 &> /dev/null && remoteDestinationOnline=true
        [ $remoteDestinationOnline ] && break
        sleep 30
done

if ! [ $remoteDestinationOnline ] ; then
        exit 110
fi

lastSnapshot=$(/sbin/zfs list -t snapshot -o name -s name | grep ^${storagePool}@ | sort | tail -1)
/sbin/zfs snapshot -r ${storagePool}@$(date -Iseconds | cut -c1-19) &>/dev/null || exit 120
newSnapshot=$(/sbin/zfs list -t snapshot -o name -s name | grep ^${storagePool}@ | sort | tail -1)

/sbin/zfs send -R -i ${lastSnapshot} ${newSnapshot} | pigz -4 | trickle -u 10240 ssh -q -i ${identifyFile} ${remoteUser}@${remoteDestination} "unpigz | sudo /sbin/zfs receive -Fduv ${storagePool}" &>/dev/null || exit 130

oldestSnapshotToKeep=$(date --date="31 days ago" +"%Y%m%d%H%M%S")
for snapshot in $(zfs list -t snapshot -o name -s name | grep ${storagePool}) ; do
        snapshotDate=$(echo $snapshot | grep -P -o '2\d{3}-[0-3]\d-[0-3]\dT[012]\d:[0-5]\d:[0-5]\d')
        if [ $(date --date="$snapshotDate" +"%Y%m%d%H%M%S") -lt $oldestSnapshotToKeep ] ; then
                /sbin/zfs destroy ${snapshot} &>/dev/null || exit 140
        fi
done
