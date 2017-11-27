#!/usr/bin/env bash

if [ ! -d venv ]
then
    python3 -m venv venv
    ./venv/bin/pip install ansible
fi

. venv/bin/activate
ansible-playbook -i farm/inventory configure-builders-playbook.yml
