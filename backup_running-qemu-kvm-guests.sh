#!/bin/bash
set -eu

backup_kvm_domain () {
    VMNAME=$1
    BKPATH="${2}/${VMNAME}"

    virsh dumpxml --security-info $VMNAME > ${BKPATH}/${VMNAME}.xml
    if [ $? -ne 0 ]; then
         echo "failed to export ${VMNAME} definition"
         exit 1
    fi

    TARGETS=$(virsh domblklist $VMNAME --details | grep "disk" | awk '{ print $3}')
    if [ "x$TARGETS" == "x" ]; then
        echo "Cannot get block device list for ${VMNAME}"
        exit 1
    fi

    IMAGES=$(virsh domblklist $VMNAME --details | grep "disk" | awk '{ print $4}')
    if [ "x$IMAGES" == "x" ]; then
        echo "Cannot get block device list for ${VMNAME}"
        exit 1
    fi

    # All vm images are in the same location
    IMAGEPATH=$(dirname $( virsh domblklist abus --details | grep 'disk' | awk '{ print $4}' ))

    DISKSPEC=""
    for t in $TARGETS; do
        DISKSPEC="$DISKSPEC $t,snapshot=external,file=${IMAGEPATH}/${VMNAME}_${t}_snapshot4backup.qcow2"
    done

    virsh snapshot-create-as --domain $VMNAME --name snapshot4backup --diskspec $DISKSPEC --disk-only --no-metadata --atomic > /dev/null
    if [ $? -ne 0 ]; then
         echo "failed to creating snapshot for ${VMNAME}"
         exit 1
    fi

    for i in $IMAGES; do
        NAME=$(basename "$i")
        cp "$i" "$BKPATH"/"$NAME"
    done

    for t in $TARGETS; do
        virsh blockcommit $VMNAME $t --active --pivot >/dev/null
        if [ $? -ne 0 ]; then
            echo "failed blockcommit for ${VMNAME}, target ${t}"
            exit 1
        fi
    done

    for t in $TARGETS; do
        rm -f "${IMAGEPATH}/${VMNAME}_${t}_snapshot4backup.qcow2"
    done
}

for d in $(virsh list | tail -n +3 | awk '{ print $2 }') ; do
    backup_kvm_domain $d /zfs/bikeshed/it/backups/qemu_kvm
done
