---
# RancherKubernetesEngine (rke) configuration file

cluster_name: ${cluster_name}

kubernetes_version: "${kubernetes_version}"

bastion_host:
  address: ${bastion_ip}
  user: ${ssh_login_user}
  ssh_key_path: ${ssh_identity_file}

nodes:
%{ for index, ip_address in master_ip_addresses ~}
  - address: ${ip_address}
    internal_address: ${ip_address}
    hostname_override: ${master_hostnames[index]}
    user: ${ssh_login_user}
    ssh_key_path: ${ssh_identity_file}
    role:
      - controlplane
      - etcd
%{ endfor ~}
%{ for index, ip_address in worker_ip_addresses ~}
  - address: ${ip_address}
    internal_address: ${ip_address}
    hostname_override: ${worker_hostnames[index]}
    user: ${ssh_login_user}
    ssh_key_path: ${ssh_identity_file}
    role:
      - worker
%{ endfor ~}

network:
  plugin: canal
  options: {}
  mtu: ${mtu}

authentication:
  strategy: x509
  sans:
    - "${api_ip_address}"

services:
  kube-api:
    extra_args:
      external-hostname: ${api_ip_address}
  kube-controller:
    extra_args:
      cluster-signing-cert-file: "/etc/kubernetes/ssl/kube-ca.pem"
      cluster-signing-key-file: "/etc/kubernetes/ssl/kube-ca-key.pem"
%{ if use_external_cloud_provider == true ~}
  kubelet:
    extra_args:
      cloud-provider: external
%{ endif ~}

# we use an ssh-agent
ssh_agent_auth: true

private_registries:
  - url: docker.io
    is_default: true
