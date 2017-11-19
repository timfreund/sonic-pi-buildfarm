#!/usr/bin/env bash

set -x

VM_ROOT=/var/lib/libvirt/images

echo "instance-id: $(uuidgen)" > metadata.txt
cloud-localds sonicpi-userdata.img userdata.txt metadata.txt
cp sonicpi-userdata.img ${VM_ROOT}/

for ci in `ls cloud-images/`;
do
    short_name=`echo ${ci} | sed -e 's/-.*//'`
    name=sonicpi-${short_name}

    virsh domstate ${name} | grep running >/dev/null
    if [ $? -eq 0 ]
    then
        virsh destroy ${name}
    fi

    rm -f /tmp/${name}.log

    virsh domstate ${name} > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        virsh undefine ${name}
    fi

    qemu-img create -f qcow2 -b ${IMAGE_ROOT}/${ci} ${VM_ROOT}/${name}.qcow2

    # virsh start ${name}
    virt-install --name ${name} \
                 --memory 1024 --vcpus 1 \
                 --import \
                 --disk ${VM_ROOT}/${name}.qcow2,bus=sata \
                 --disk ${VM_ROOT}/sonicpi-userdata.img,device=cdrom \
                 --check path_in_use=off \
                 --network network=default \
                 --serial file,path=/tmp/${name}.log \
                 --noautoconsole

done

