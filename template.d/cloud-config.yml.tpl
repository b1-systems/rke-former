---
# cloud-config

hostname: ${hostname}

apt_update: true
apt_upgrade: false

packages:
  - software-properties-common
  - bash-completion
  - inetutils-ping
  - docker.io
  - dnsutils
  - screen
  - less
  - vim
  - jq

runcmd:
  - systemctl enable --now docker
%{ if hostname == "bastion" ~}
  - curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.8/bin/linux/amd64/kubectl
  - install -m0755 kubectl /usr/local/bin/kubectl
  - kubectl completion bash > /etc/bash_completion.d/kubectl
  - curl -LO https://github.com/rancher/rke/releases/download/v1.2.9/rke_linux-amd64
  - install -m0755 rke_linux-amd64 /usr/local/bin/rke
  - curl -LO https://get.helm.sh/helm-v3.6.2-linux-amd64.tar.gz
  - tar -xf helm-v3.6.2-linux-amd64.tar.gz linux-amd64/helm
  - install -m0755 linux-amd64/helm /usr/local/bin/helm
  - helm completion bash > /etc/bash_completion.d/helm
%{ endif ~}

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

%{ if certificates != "" ~}
ca-certs:
  trusted:
    - |
      ${indent(6,certificates)}
%{ endif ~}

%{ if hosts != "" ~}
manage_etc_hosts: false
%{ endif ~}

write_files:
%{ if hosts != "" ~}
  - path: /etc/hosts
    content: |
      ${indent(6,hosts)}
%{ endif ~}
  - path: /etc/docker/daemon.json
    content: |
      {
        "log-driver": "json-file",
        "log-opts": {
          "max-size": "25m",
          "max-file": "3"
        }
      }
  - path: /etc/ssh/sshd_config
    content: |
      HostKey /etc/ssh/ssh_host_rsa_key
      HostKey /etc/ssh/ssh_host_dsa_key
      HostKey /etc/ssh/ssh_host_ecdsa_key
      HostKey /etc/ssh/ssh_host_ed25519_key
      SyslogFacility AUTH
      LogLevel INFO
      PermitRootLogin no
      StrictModes yes
      IgnoreRhosts yes
      PermitEmptyPasswords no
      PubkeyAuthentication yes
      PrintLastLog yes
      TCPKeepAlive yes
      AcceptEnv LANG LC_*
      Subsystem sftp /usr/lib/openssh/sftp-server
      UsePAM yes
      MaxStartups 100:50:120
      ClientAliveCountMax 100
      MaxSessions 100
