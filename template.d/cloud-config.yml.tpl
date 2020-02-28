---
# cloud-config

manage_etc_hosts: true

apt_update: true
apt_upgrade: false

packages:
  - software-properties-common
  - docker.io

groups:
  - docker

users:
  - default
  - name: ${ssh_login_user}
    shell: /bin/bash
    groups: admin, docker, users
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${ssh_pubkey}
