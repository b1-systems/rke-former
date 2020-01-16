##      _         ____                       
##  _ _| |_____  / / _|___ _ _ _ __  ___ _ _ 
## | '_| / / -_)/ /  _/ _ \ '_| '  \/ -_) '_|
## |_| |_\_\___/_/|_| \___/_| |_|_|_\___|_|  
##   B1 DevOps Days '20 : Kubernetes Deployment                                          
##

## --- versions ---
terraform {
  required_version = ">= 0.12"
}

## --- OpenStack ---

variable openstack_auth_url {
  description = "OpenStack Keystone auth_url for Kubernetes Provider Plugin"

}
variable openstack_password {
  description = "OpenStack Keystone Password for Kubernetes Provider Plugin"
}

# get OpenStack Scope information
data "openstack_identity_auth_scope_v3" "scope" {
  name = "auth_scope"
}

# SSH pubkey for OpenStack Keypair
variable "ssh_key_file" {
  default = "./terraform"
}

# Prefix for OpenStack objects
variable "prefix_name" {
  description = "prefix for OpenStack Nova instances"
  default     = "example"
}

## --- OpenStack Neutron (Networking) ---

# OpenStack Network
variable "project_network_cidr" {
  default = "10.0.10.0/24"
}

# OpenStack Network for external Net, e.g. l3 router
variable "external_network_id" {
  default = "0647c0a0-862c-4c7e-9433-4558fcc5573b"
}

# OpenStac floating pool Name
variable "floatingip_pool" {
  default = "public"
}

## --- bastion host ---

# OpenStack flavor
variable "bastionhost_flavor" {
  default = "2C-2GB-10GB"
}

# OpenStack Image ID for bastion host
variable "bastionhost_image_id" {
  default = "647aebdc-afe4-490f-9d1d-e0e5f1fd0da5"
}

variable "bastionhost_sshuser" {
  default = "rancher"
}

## --- master nodes ---

# amount of master node
variable "master_count" {
  description = "Amount of master nodes for the k8s clusters"
  default     = 1
}

# Openstack flavor
variable "master_flavor" {
  default = "2C-4GB-40GB"
}

# Openstack Image ID
variable "master_image_id" {
  default = "647aebdc-afe4-490f-9d1d-e0e5f1fd0da5"
}

variable "master_sshuser" {
  default = "rancher"
}

## --- worker nodes ---

variable "worker_count" {
  description = "Amount of worker nodes for the k8s clusters"
  default     = 2
}

# OpenStack flavor Name
variable "worker_flavor" {
  default = "2C-2GB-10GB"
}

# OpenStack Image ID
variable "worker_image_id" {
  default = "647aebdc-afe4-490f-9d1d-e0e5f1fd0da5"
}

variable "worker_sshuser" {
  default = "rancher"
}

## --- OpenStack Keypair ---

resource "openstack_compute_keypair_v2" "rke-former-keypair" {
  name       = "${var.prefix_name}-keypair"
  public_key = file("${var.ssh_key_file}.pub")
}

## OpenStack Networking

# Project Network
resource "openstack_networking_network_v2" "rke-former-net" {
  name           = "${var.prefix_name}-rke-former-net"
  admin_state_up = "true"
}

# Tenant Subnet
resource "openstack_networking_subnet_v2" "rke-former-sn" {
  name       = "${var.prefix_name}-rke-former-sn"
  network_id = openstack_networking_network_v2.rke-former-net.id
  cidr       = var.project_network_cidr
  ip_version = 4
}

# l3 router
resource "openstack_networking_router_v2" "rke-former-rtr" {
  name                = "${var.prefix_name}-rke-former-rtr"
  admin_state_up      = "true"
  external_network_id = var.external_network_id
}

# Tenant l3 router gateway and interface
resource "openstack_networking_router_interface_v2" "rke-former-rtr" {
  router_id = openstack_networking_router_v2.rke-former-rtr.id
  subnet_id = openstack_networking_subnet_v2.rke-former-sn.id
}

# Security Group
resource "openstack_compute_secgroup_v2" "sg-22-tcp" {
  name        = "${var.prefix_name}-sg-22-tcp"
  description = "22/tcp (ssh)"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# Security Group
resource "openstack_compute_secgroup_v2" "sg-6443-tcp" {
  name        = "${var.prefix_name}-sg-6443-tcp"
  description = "6443/tcp (ssh)"

  rule {
    from_port   = 6443
    to_port     = 6443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "sg-icmp-all" {
  name        = "${var.prefix_name}-sg-icmp-all"
  description = "0/icmp all"

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

##  --- bastionhost ---

resource "openstack_networking_floatingip_v2" "k8s-bastionhost-fip" {
  pool       = var.floatingip_pool
  depends_on = [openstack_networking_router_interface_v2.rke-former-rtr]
}

resource "openstack_compute_instance_v2" "k8s-bastionhost" {
  name            = "${var.prefix_name}-bastionhost"
  flavor_name     = var.bastionhost_flavor
  image_id        = var.bastionhost_image_id
  security_groups = ["default", openstack_compute_secgroup_v2.sg-22-tcp.name, openstack_compute_secgroup_v2.sg-icmp-all.name]
  key_pair        = openstack_compute_keypair_v2.rke-former-keypair.name
  config_drive    = true

  network {
    uuid = openstack_networking_network_v2.rke-former-net.id
  }
}

resource "openstack_compute_floatingip_associate_v2" "k8s-bastionhost-fip" {
  floating_ip = openstack_networking_floatingip_v2.k8s-bastionhost-fip.address
  instance_id = openstack_compute_instance_v2.k8s-bastionhost.id
}

output "bastion" {
  value = [openstack_compute_floatingip_associate_v2.k8s-bastionhost-fip.floating_ip]
}

data "template_file" "k8s-bastionhost" {
  template = file("${path.module}//template.d/rke-bastionhost.yml.tpl")

  vars = {
    bastionhost_address = openstack_compute_floatingip_associate_v2.k8s-bastionhost-fip.floating_ip
    bastionhost_sshuser = var.bastionhost_sshuser
  }
}


# --- k8s master ---
#
resource "openstack_compute_instance_v2" "k8s-master" {
  depends_on   = [openstack_networking_subnet_v2.rke-former-sn]
  name         = "${var.prefix_name}-master${count.index + 1}"
  count        = var.master_count
  image_id     = var.master_image_id
  flavor_name  = var.master_flavor
  key_pair     = openstack_compute_keypair_v2.rke-former-keypair.name
  config_drive = true

  network {
    uuid = openstack_networking_network_v2.rke-former-net.id
  }
}

output "master-ip" {
  value = [openstack_compute_instance_v2.k8s-master.*.network.0.fixed_ip_v4]
}

data "template_file" "k8s-master" {
  count    = var.master_count
  template = file("${path.module}/template.d/rke-master.tpl")

  vars = {
    master_address = element(
      openstack_compute_instance_v2.k8s-master.*.network.0.fixed_ip_v4,
      count.index,
    )
    master_sshuser              = var.master_sshuser
    loadbalancer-cp-floating-ip = "${openstack_networking_floatingip_v2.lbcp-floating-extern.address}"
  }
}

## --- kubernetes worker ---

resource "openstack_compute_instance_v2" "k8s-worker" {
  depends_on   = [openstack_networking_subnet_v2.rke-former-sn]
  name         = "${var.prefix_name}-worker${count.index + 1}"
  count        = var.worker_count
  image_id     = var.worker_image_id
  flavor_name  = var.worker_flavor
  key_pair     = openstack_compute_keypair_v2.rke-former-keypair.name
  config_drive = true

  network {
    uuid = openstack_networking_network_v2.rke-former-net.id
  }
}

output "worker-ips" {
  value = [openstack_compute_instance_v2.k8s-worker.*.network.0.fixed_ip_v4]
}

data "template_file" "k8s-worker" {
  count    = var.worker_count
  template = file("${path.module}/template.d/rke-worker.tpl")

  vars = {
    worker_address = element(
      openstack_compute_instance_v2.k8s-worker.*.network.0.fixed_ip_v4,
      count.index,
    )
    worker_sshuser = var.worker_sshuser
  }
}

## --- Loadbalaner for Controlplane ---

resource "openstack_lb_loadbalancer_v2" "k8scp" {
  name          = "${var.prefix_name}-lb-cp"
  vip_subnet_id = openstack_networking_subnet_v2.rke-former-sn.id
  description   = "loadbalancer for ${var.prefix_name} Controlplane"
  depends_on    = [openstack_compute_instance_v2.k8s-master]
}

resource "openstack_networking_floatingip_v2" "lbcp-floating-extern" {
  pool       = var.floatingip_pool
  port_id    = openstack_lb_loadbalancer_v2.k8scp.vip_port_id
  depends_on = [openstack_lb_loadbalancer_v2.k8scp]
}

output "loadbalancer-cp" {
  value = [openstack_networking_floatingip_v2.lbcp-floating-extern.address]
}

resource "openstack_lb_listener_v2" "k8scp-6443" {
  name            = "${var.prefix_name}-lbcp-ln-6443"
  protocol        = "TCP"
  protocol_port   = 6443
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8scp.id
  depends_on      = [openstack_lb_loadbalancer_v2.k8scp]
}

resource "openstack_lb_pool_v2" "k8scp-pl-6443" {
  name        = "${var.prefix_name}-lbcp-ln-6443-pl"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8scp-6443.id
  depends_on  = [openstack_lb_listener_v2.k8scp-6443]
}

resource "openstack_lb_member_v2" "k8scp-mb-6443" {
  count = var.master_count
  address = element(
    openstack_compute_instance_v2.k8s-master.*.access_ip_v4,
    count.index,
  )
  protocol_port = 6443
  pool_id       = openstack_lb_pool_v2.k8scp-pl-6443.id
  subnet_id     = openstack_networking_subnet_v2.rke-former-sn.id
  depends_on    = [openstack_lb_pool_v2.k8scp-pl-6443]
}

resource "openstack_lb_monitor_v2" "k8scp-hc-6443" {
  name        = "${var.prefix_name}-lbcp-hc-6443"
  pool_id     = openstack_lb_pool_v2.k8scp-pl-6443.id
  type        = "TCP"
  delay       = 2
  timeout     = 2
  max_retries = 2
  depends_on  = [openstack_lb_member_v2.k8scp-mb-6443]
}

## --- Loadbalancer for Ingress ---

resource "openstack_lb_loadbalancer_v2" "k8s" {
  name          = "${var.prefix_name}-lb"
  vip_subnet_id = openstack_networking_subnet_v2.rke-former-sn.id
  description   = "loadbalancer for ${var.prefix_name}"
  depends_on    = [openstack_compute_instance_v2.k8s-worker]
}

resource "openstack_networking_floatingip_v2" "lb-floating-extern" {
  pool       = var.floatingip_pool
  port_id    = openstack_lb_loadbalancer_v2.k8s.vip_port_id
  depends_on = [openstack_lb_loadbalancer_v2.k8s]
}

output "loadbalancer-ingress" {
  value = [openstack_networking_floatingip_v2.lb-floating-extern.address]
}

resource "openstack_lb_listener_v2" "k8s-80" {
  name            = "${var.prefix_name}-lb-ln-80"
  protocol        = "TCP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
  depends_on      = [openstack_lb_loadbalancer_v2.k8s]
}

resource "openstack_lb_pool_v2" "k8s-pl-80" {
  name        = "${var.prefix_name}-lb-ln-80-pl"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8s-80.id
  depends_on  = [openstack_lb_listener_v2.k8s-80]
}

resource "openstack_lb_member_v2" "k8s-mb-80" {
  count = var.worker_count
  address = element(
    openstack_compute_instance_v2.k8s-worker.*.access_ip_v4,
    count.index,
  )
  protocol_port = 80
  pool_id       = openstack_lb_pool_v2.k8s-pl-80.id
  subnet_id     = openstack_networking_subnet_v2.rke-former-sn.id
  depends_on    = [openstack_lb_pool_v2.k8s-pl-80]
}

resource "openstack_lb_monitor_v2" "k8s-hc-80" {
  name        = "${var.prefix_name}-lb-hc-80"
  pool_id     = openstack_lb_pool_v2.k8s-pl-80.id
  type        = "TCP"
  delay       = 2
  timeout     = 2
  max_retries = 2
  depends_on  = [openstack_lb_member_v2.k8s-mb-80]
}

resource "openstack_lb_listener_v2" "k8s-443" {
  name            = "${var.prefix_name}-lb-ln-443"
  protocol        = "TCP"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s.id
  depends_on      = [openstack_lb_loadbalancer_v2.k8s]
}

resource "openstack_lb_pool_v2" "k8s-pl-443" {
  name        = "${var.prefix_name}-lb-ln-443-pl"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8s-443.id
  depends_on  = [openstack_lb_listener_v2.k8s-443]
}

resource "openstack_lb_member_v2" "k8s-mb-443" {
  count = var.worker_count
  address = element(
    openstack_compute_instance_v2.k8s-worker.*.access_ip_v4,
    count.index,
  )
  protocol_port = 443
  pool_id       = openstack_lb_pool_v2.k8s-pl-443.id
  subnet_id     = openstack_networking_subnet_v2.rke-former-sn.id
  depends_on    = [openstack_lb_pool_v2.k8s-pl-443]
}

resource "openstack_lb_monitor_v2" "k8s-hc-443" {
  name        = "${var.prefix_name}-lb-hc-443"
  pool_id     = openstack_lb_pool_v2.k8s-pl-443.id
  type        = "TCP"
  delay       = 2
  timeout     = 2
  max_retries = 2
  depends_on  = [openstack_lb_member_v2.k8s-mb-443]
}

# --- rancher-kubernetes-engine (rke) ---

data "template_file" "cluster-config" {
  template = file("${path.module}/template.d/rke-cluster.yml.tpl")

  vars = {
    bastionhost                  = join("\n", data.template_file.k8s-bastionhost.*.rendered)
    master                       = join("\n", data.template_file.k8s-master.*.rendered)
    worker                       = join("\n", data.template_file.k8s-worker.*.rendered)
    loadbalancer-cp-floating-ip  = openstack_networking_floatingip_v2.lbcp-floating-extern.address
    provider_openstack_lb_subnet = openstack_networking_subnet_v2.rke-former-sn.id
    openstack_username           = data.openstack_identity_auth_scope_v3.scope.user_name
    openstack_password           = var.openstack_password
    openstack_auth_url           = var.openstack_auth_url
    tenant_id                    = data.openstack_identity_auth_scope_v3.scope.project_id
    domain_id                    = data.openstack_identity_auth_scope_v3.scope.project_domain_id
  }
}

resource "local_file" "cluster-config" {
  content              = data.template_file.cluster-config.rendered
  filename             = "${path.module}/rke/cluster.yml"
  directory_permission = "750"
  file_permission      = "600"
}

# eof
