---
# cloud-config

hostname: ${hostname}

manage_etc_hosts: true

apt_update: true
apt_upgrade: false

packages:
  - software-properties-common
  - docker.io

runcmd:
  - systemctl enable --now docker

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

%{ if trusted_ca_certs != "" ~}
ca-certs:
  trusted:
    - |
      ${indent(6,trusted_ca_certs)}
%{ endif ~}
