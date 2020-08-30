#!/bin/sh
set -eu

restore_vm () {
    VMNAME=$1
    BKPATH="${2}/${VMNAME}"

    cp -f --sparse=always ${BKPATH}/${VMNAME}.qcow2 /mnt/libvirt/images/
    if [ $? -ne 0 ]; then 
        echo "failed copying ${BKPATH}/${VMNAME}.qcow2 to /mnt/libvirt/images"
        exit 1
    fi

    virsh define ${BKPATH}/${VMNAME}.xml > /dev/null
    if [ $? -ne 0 ]; then 
        echo "error defining ${BKPATH}/${VMNAME}.xml"
        exit 1
    fi

    chown libvirt-qemu:libvirt-qemu /mnt/libvirt/images/${VMNAME}.qcow2
    if [ $? -ne 0 ]; then 
        echo "error changing owner: /mnt/libvirt/images/${VMNAME}.qcow2"
        exit 1
    fi

    chmod 660 /mnt/libvirt/images/${VMNAME}.qcow2
    if [ $? -ne 0 ]; then 
        echo "error changing permissions: /mnt/libvirt/images/${VMNAME}.qcow2"
        exit 1
    fi
}

[ `virsh list | tail -n +3 | wc -l` -gt 1 ] && exit 

for d in $(ls /zfs/bikeshed/it/backups/qemu_kvm) ; do
    restore_vm $d /zfs/bikeshed/it/backups/qemu_kvm
done
