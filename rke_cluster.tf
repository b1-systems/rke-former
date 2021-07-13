locals {
  master_hostnames = openstack_compute_instance_v2.master.*.name
  master_ip_addresses = openstack_compute_instance_v2.master.*.access_ip_v4
  worker_hostnames = openstack_compute_instance_v2.worker.*.name
  worker_ip_addresses = openstack_compute_instance_v2.worker.*.access_ip_v4
}

resource "local_file" "cluster_config" {
  filename = "${path.module}/cluster.yml"
  directory_permission = "750"
  file_permission = "600"
  content = templatefile("${path.module}/template.d/rke-cluster.yml.tpl", {
    cluster_name = var.cluster_name
    bastion_ip = openstack_compute_floatingip_associate_v2.bastion.floating_ip
    master_hostnames = local.master_hostnames
    master_ip_addresses = local.master_ip_addresses
    worker_hostnames = local.worker_hostnames
    worker_ip_addresses = local.worker_ip_addresses
    api_ip_address = openstack_networking_floatingip_v2.k8s_cluster.address
    subnet_id = openstack_networking_subnet_v2.cluster_network.id
    ssh_login_user = var.ssh_login_user
    ssh_identity_file = var.ssh_identity_file
    kubernetes_version = var.kubernetes_version
  })
}
