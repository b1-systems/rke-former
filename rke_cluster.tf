resource "local_file" "cluster_config" {
  filename = "${path.module}/cluster.yml"
  directory_permission = "750"
  file_permission = "600"
  content = templatefile("${path.module}/template.d/rke-cluster.yml.tpl", {
    bastion_ip = openstack_compute_floatingip_associate_v2.bastion.floating_ip 
    master_ips = openstack_compute_instance_v2.master.*.access_ip_v4
    worker_ips = openstack_compute_instance_v2.worker.*.access_ip_v4
    api_ip_address = openstack_networking_floatingip_v2.k8s_cluster.address
    subnet_id = openstack_networking_subnet_v2.cluster_network.id
    openstack_username = data.openstack_identity_auth_scope_v3.scope.user_name
    openstack_password = var.openstack_password
    openstack_auth_url = var.openstack_auth_url
    openstack_project_id = data.openstack_identity_auth_scope_v3.scope.project_id
    openstack_domain_id = data.openstack_identity_auth_scope_v3.scope.project_domain_id
    ssh_login_user = var.ssh_login_user
    ssh_identity_file = var.ssh_identity_file
    kubernetes_version = var.kubernetes_version
    trusted_ca_certs = fileexists(var.trusted_ca_certs) ? file(var.trusted_ca_certs) : ""
  })
}
