resource "local_file" "bastion_ssh_config" {
  filename = "ssh_config"
  file_permission = "0644"
  content = templatefile("${path.module}/template.d/ssh_config.tpl", {
    ip_address = openstack_compute_floatingip_associate_v2.bastion.floating_ip
    ssh_login_user = var.ssh_login_user
    ssh_identity_file = var.ssh_identity_file
  })
}
