data "template_file" "cloud_config_bastion" {
  template = file("${path.module}/template.d/cloud-config.yml.tpl")
  vars = {
    hostname = "bastion"
    ssh_login_user = var.ssh_login_user
    ssh_pubkey = file(var.ssh_pubkey_file)
    hosts = fileexists(var.hosts) ? file(var.hosts) : ""
    certificates = fileexists(var.certificates) ? file(var.certificates) : ""
  }
}

data "template_cloudinit_config" "bastion" {
  base64_encode = false
  gzip = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = data.template_file.cloud_config_bastion.rendered
  }
}

resource "openstack_compute_instance_v2" "bastion" {
  name = "${var.prefix}-bastion"
  config_drive = true
  image_name = var.image_bastion
  flavor_name = var.flavor_bastion
  key_pair = openstack_compute_keypair_v2.ssh_key.id
  user_data = data.template_cloudinit_config.bastion.rendered
  availability_zone_hints = var.availability_zone_hints_compute[0]
  network { uuid = openstack_networking_network_v2.cluster_network.id }
  security_groups = [ "default", openstack_networking_secgroup_v2.ssh.id ]
}

resource "openstack_networking_floatingip_v2" "bastion" {
  pool = var.external_network_name
  depends_on = [openstack_networking_router_interface_v2.external]
}

resource "openstack_compute_floatingip_associate_v2" "bastion" {
  instance_id = openstack_compute_instance_v2.bastion.id
  floating_ip = openstack_networking_floatingip_v2.bastion.address
}
