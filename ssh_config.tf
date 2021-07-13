locals {
  hosts = {
    for instance in concat(openstack_compute_instance_v2.master,
                           openstack_compute_instance_v2.worker):
      instance.name => instance.access_ip_v4
  }
}

resource "local_file" "ssh_config" {
  filename = "ssh_config"
  file_permission = "0644"
  content = templatefile("${path.module}/template.d/ssh_config.tpl", {
    hosts = local.hosts
    ssh_login_user = var.ssh_login_user
    ssh_identity_file = var.ssh_identity_file
    ip_address = openstack_compute_floatingip_associate_v2.bastion.floating_ip
  })
}
