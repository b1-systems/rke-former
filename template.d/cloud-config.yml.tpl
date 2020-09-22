---
# cloud-config

hostname: ${hostname}

apt_update: true
apt_upgrade: false

packages:
  - software-properties-common
  - inetutils-ping
  - docker.io
  - dnsutils
  - screen
  - less
  - vim

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

%{ if hosts != "" ~}
manage_etc_hosts: false
write_files:
  - path: /etc/hosts
    content: |
      ${indent(6,hosts)}
    owner: root:root
    permissions: '0644'
%{ endif ~}

%{ if trusted_ca_certs != "" ~}
ca-certs:
  trusted:
    - |
      ${indent(6,trusted_ca_certs)}
%{ endif ~}
