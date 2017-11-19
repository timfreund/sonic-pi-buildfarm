#!/usr/bin/env bash

set -x

IMAGE_ROOT=`pwd`/cloud-images/
VM_ROOT=/var/lib/libvirt/images

LIBVIRT_POOL_NAME=default
LIBVIRT_NET_NAME=default

mkdir -p farm/.ssh
chmod 700 farm/.ssh
if [ ! -e farm/.ssh/id_rsa ]
then
    ssh-keygen -N "" -f farm/.ssh/id_rsa
fi

erb ssh_public_key="`cat farm/.ssh/id_rsa.pub`" cloud-init/userdata.txt.erb > userdata.txt
echo "instance-id: $(uuidgen)" > metadata.txt
cloud-localds sonicpi-userdata.img userdata.txt metadata.txt
virsh vol-upload sonicpi-userdata.img sonicpi-userdata.img --pool ${LIBVIRT_POOL_NAME}
rm userdata.txt metadata.txt

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

    virsh vol-upload ${name}.qcow2 ${IMAGE_ROOT}/${ci} --pool ${LIBVIRT_POOL_NAME}

    # virsh start ${name}
    virt-install --name ${name} \
                 --memory 1024 --vcpus 1 \
                 --import \
                 --disk vol=${LIBVIRT_POOL_NAME}/${name}.qcow2,bus=sata \
                 --disk vol=${LIBVIRT_POOL_NAME}/sonicpi-userdata.img,device=cdrom \
                 --check path_in_use=off \
                 --network network=${LIBVIRT_NET_NAME} \
                 --serial file,path=/tmp/${name}.log \
                 --noautoconsole

    #    --disk ${VM_ROOT}/${name}.qcow2,bus=sata \

done

