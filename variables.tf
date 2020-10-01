variable "prefix" {
  description = "Prefix for OpenStack resource object names"
  default = "rke"
}

variable "master_count" {
  description = "Amount of master nodes to spawn up"
  default = 1
}

variable "worker_count" {
  description = "Amount of worker nodes to spawn up"
  default = 1
}

variable "kubernetes_version" {
  description = "RKE supported Kubernetes to install"
  default = "v1.18.8-rancher1-1"
}

variable "external_network_name" {
  description = "Name of external network making the cluster reachable via FIP"
  default = "external"
}

variable "external_network_id" {
  description = "ID of external network"
  default = "293bea64-1572-4016-b002-2da2060a888e"
}

variable "availability_zone_hints_compute" {
  description = "Availability zone to use for compute resources"
  default = ["nova"]
}

variable "availability_zone_hints_network" {
  description = "Availability zone to use for network resources"
  default = ["nova"]
}

variable "use_octavia" {
  description = "Use Octavia LBaaSv2"
  default = true
}

variable "insecure" {
  description = "Disable server certificate verification"
  default = false
}

variable "kubernetes_api_port" {
  description = "Kubernetes API port"
  default = 6443
}

variable "kubernetes_nodeport_range_min" {
  description = "Kubernetes NodePort range lower end"
  default = 30000
}

variable "kubernetes_nodeport_range_max" {
  description = "Kubernetes NodePort range upper end"
  default = 32767
}

variable "openstack_auth_url" {
  description = "OpenStack auth_url for Kubernetes Provider Plugin"

}
variable "openstack_password" {
  description = "OpenStack Password for Kubernetes Provider Plugin"
}

variable "cluster_network_cidr" {
  description = "Kubernetes cluster network address"
  default = "10.0.10.0/24"
}

variable "cluster_network_mtu" {
  description = "MTU for Kubernetes cluster network"
  default = "1450"
}


variable "ssh_identity_file" {
  description = "Location of SSH identity file"
  default = "~/.ssh/id_rsa"
}

variable "ssh_pubkey_file" {
  description = "Location of SSH pubkey file"
  default = "~/.ssh/id_rsa.pub"
}

variable "ssh_login_user" {
  description = "Default login user for cluster nodes"
  default = "rancher"
}

variable "flavor_bastion" {
  description = "The instance flavor used to create bastion host"
  default = "1C-512MB-10GB"
}

variable "flavor_master" {
  description = "The instance flavor used to create master nodes"
  default = "1C-2GB-10GB"
}

variable "flavor_worker" {
  description = "The instance flavor used to create worker nodes"
  default = "2C-4GB-10GB"
}

variable "image_bastion" {
  description = "The image used to create bastion host"
  default = "Ubuntu Minimal 20.04"
}

variable "image_nodes" {
  description = "The image used to create Kubernetes node instances"
  default = "Ubuntu Minimal 20.04"
}

variable "hosts" {
  description = "Unix hosts file to include on master and worker nodes"
  default = "hosts"
}

variable "trusted_ca_certs" {
  description = "File with trusted CA certificates in PEM format"
  default = "ca-certs.pem"
}

variable "additional_routes" {
  description = "Define routes to additional networks"
  default = {}
  type = map(
    object({
      # ID of additional network
      network_id = string
      # Network CIDR of the additional network (example: 172.16.100.0/24)
      network_cidr = string
      # Router IP in the Kubernetes cluster network (example: 10.0.10.5)
      router_ip_address = string
    })
  )
}
