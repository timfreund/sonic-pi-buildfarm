#!/usr/bin/env bash

set -x

cat /dev/null > farm/inventory
echo "[sonicpi]" > farm/inventory

for ci in `ls cloud-images/`;
do
    short_name=`echo ${ci} | sed -e 's/-.*//'`
    name=sonicpi-${short_name}

    virsh domstate ${name} | grep running >/dev/null
    if [ $? -eq 0 ]
    then
        interfaces=`virsh domifaddr ${name} | grep : | head -1 | wc -l`
        while [ $interfaces -eq 0 ]
        do
            sleep 2
            interfaces=`virsh domifaddr ${name} | grep : | head -1 | wc -l`
        done
        ip=`virsh domifaddr ${name} | grep : | sed -e 's/.* //' -e 's|/.*||'`
        echo "${name} ansible_host=${ip}" >> farm/inventory
    else
        echo "${name} isn't running, can't inspect interface state"
    fi
done

cat >>farm/inventory<<EOF

[sonicpi:vars]
ansible_user=sonicpi
ansible_ssh_private_key_file=farm/.ssh/id_rsa
ansible_ssh_common_args="-oStrictHostKeyChecking=no"
ansible_python_interpreter=/usr/bin/python3

EOF
