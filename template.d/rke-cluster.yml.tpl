---
# RancherKubernetesEngine (rke) configuration file

cluster_name: ${cluster_name}

kubernetes_version: "${kubernetes_version}"

bastion_host:
  address: ${bastion_ip}
  user: ${ssh_login_user}
  ssh_key_path: ${ssh_identity_file}

nodes:
%{ for ip_address in master_ips ~}
  - address: ${ip_address}
    internal_address: ${ip_address}
    user: ${ssh_login_user}
    ssh_key_path: ${ssh_identity_file}
    role:
      - controlplane
      - etcd
%{ endfor ~}
%{ for ip_address in worker_ips ~}
  - address: ${ip_address}
    internal_address: ${ip_address}
    user: ${ssh_login_user}
    ssh_key_path: ${ssh_identity_file}
    role:
      - worker
%{ endfor ~}

network:
  plugin: canal
  options: {}

authentication:
  strategy: x509
  sans:
    - "${api_ip_address}"

services:
  kube-api:
    extra_args:
      external-hostname: ${api_ip_address}

# we use an ssh-agent
ssh_agent_auth: true

private_registries:
  - url: docker.io
    is_default: true
