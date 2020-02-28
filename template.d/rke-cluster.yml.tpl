---
# RancherKubernetesEngine (rke) configuration file

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

kubernetes_version: "v1.16.3-rancher1-1"

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
    load_balancer:
      subnet-id: ${subnet_id}
      manage-security-groups: true
    block_storage:
      ignore-volume-az: true

addons: |-
  ---
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: bc-default
    annotations:
      storageclass.kubernetes.io/is-default-class: true
  provisioner: kubernetes.io/cinder

private_registries:
  - url: docker.io
    is_default: true
