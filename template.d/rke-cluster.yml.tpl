---
# RancherKubernetesEngine (rke) configuration file

cluster_name: ${cluster_name}

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
%{ if trusted_ca_certs != "" ~}
  kube-controller:
    extra_binds:
      - "/usr/share/ca-certificates:/usr/share/ca-certificates"
  kubelet:
    extra_binds:
      - "/usr/share/ca-certificates:/usr/share/ca-certificates"
%{ endif ~}
  kube-api:
    extra_args:
      external-hostname: ${api_ip_address}

kubernetes_version: "${kubernetes_version}"

# we use an ssh-agent
ssh_agent_auth: true

cloud_provider:
  name: openstack
  openstackCloudProvider:
    global:
      auth-url: ${openstack_auth_url}
      username: ${openstack_username}
      password: ${openstack_password}
      tenant-id: ${openstack_project_id}
      domain-id: ${openstack_domain_id}
%{ if trusted_ca_certs != "" ~}
      ca-file: /usr/share/ca-certificates/cloud-init-ca-certs.crt
%{ endif ~}
    load_balancer:
      subnet-id: ${subnet_id}
      use-octavia: true
      create-monitor: true
      monitor-delay: "5s"
      monitor-timeout: "60s"
      monitor-max-retries: 5
      manage-security-groups: true
    block_storage:
      ignore-volume-az: true

private_registries:
  - url: docker.io
    is_default: true
