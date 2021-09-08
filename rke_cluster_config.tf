locals {
  master = {
    for instance in openstack_compute_instance_v2.master:
      instance.name => instance.access_ip_v4
  }
  worker = {
    for instance in openstack_compute_instance_v2.worker:
      instance.name => instance.access_ip_v4
  }
}

resource "local_file" "rke_cluster_config" {
  filename = "${path.module}/cluster.yml"
  directory_permission = "750"
  file_permission = "600"
  content = templatefile("${path.module}/template.d/rke_cluster_config.yml.tpl", {
    mtu = var.cni_mtu
    master = local.master
    worker = local.worker
    cluster_name = var.cluster_name
    ssh_login_user = var.ssh_login_user
    ssh_identity_file = var.ssh_identity_file
    docker_registries = var.docker_registries
    kubernetes_version = var.kubernetes_version
    use_external_cloud_provider = var.use_external_cloud_provider
    subnet_id = openstack_networking_subnet_v2.cluster_network.id
    api_ip_address = openstack_networking_floatingip_v2.k8s_cluster.address
    bastion_ip = openstack_compute_floatingip_associate_v2.bastion.floating_ip
  })
}
