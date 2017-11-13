#!/usr/bin/env bash

set -xe 
IMAGE_ROOT=/data/media/iso/cloud
VM_ROOT=/var/lib/libvirt/images

echo "instance-id: $(uuidgen)" > metadata.txt
cloud-localds sonicpi-userdata.img userdata.txt metadata.txt
cp sonicpi-userdata.img ${VM_ROOT}/

for ci in `cat cloud-images.txt`;
do
    short_name=`echo ${ci} | sed -e 's/-.*//'`
    name=sonicpi-${short_name}

    virsh destroy ${name}
    rm /tmp/${name}.log
    
    virsh undefine ${name}

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

