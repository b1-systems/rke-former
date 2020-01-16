# -- 
# RancherKubernetesEngine (rke) configuration file
# WIP - for Demo use
# --

# bastionhost
${bastionhost}

# kubernetes nodes
nodes:
${master}
${worker}

# network settings
network:
  plugin: canal
  options: {}

authentication:
    strategy: x509
    sans:
      - "${loadbalancer-cp-floating-ip}"

services:
  kube-api:
    extra_args:  
      external-hostname: ${loadbalancer-cp-floating-ip}

# kubernetes version
kubernetes_version: "v1.16.3-rancher1-1"

# we use an ssh-agent
ssh_agent_auth: true

# cloud-provider
cloud_provider:
  name: openstack
  openstackCloudProvider:
    global:
      auth-url: ${openstack_auth_url}
      username: ${openstack_username}
      password: ${openstack_password}
      tenant-id: ${tenant_id}
      domain-id: ${domain_id}
    load_balancer:
      subnet-id: ${provider_openstack_lb_subnet}
      manage-security-groups: true
    block_storage:
      ignore-volume-az: true

# add more
addons: |-
  ---
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: bc-default
    annotations:
      storageclass.kubernetes.io/is-default-class: true
  provisioner: kubernetes.io/cinder
