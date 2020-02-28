resource "openstack_compute_keypair_v2" "ssh_key" {
  name = "${var.prefix}-rke-former"
  public_key = file(var.ssh_pubkey_file)
}

data "template_file" "cloud_config" {
  template = file("${path.module}/template.d/cloud-config.yml.tpl")
  vars = {
    ssh_login_user = var.ssh_login_user
    ssh_pubkey = file(var.ssh_pubkey_file)
  }
}

data "template_cloudinit_config" "nodes" {
  base64_encode = false
  gzip = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = data.template_file.cloud_config.rendered
  }
}

resource "openstack_compute_instance_v2" "bastion" {
  name = "${var.prefix}-bastion"
  image_name = var.image_bastion
  flavor_name = var.flavor_bastion
  key_pair = openstack_compute_keypair_v2.ssh_key.name
  user_data = data.template_cloudinit_config.nodes.rendered
  config_drive = true
  security_groups = ["default", openstack_networking_secgroup_v2.ssh.name]
  network { name = openstack_networking_network_v2.cluster_network.name }
}

resource "openstack_networking_floatingip_v2" "bastion" {
  pool = var.external_network_name
  depends_on = [openstack_networking_router_interface_v2.external]
}

resource "openstack_compute_floatingip_associate_v2" "bastion" {
  instance_id = openstack_compute_instance_v2.bastion.id
  floating_ip = openstack_networking_floatingip_v2.bastion.address
}

resource "openstack_compute_instance_v2" "master" {
  count = var.master_count
  name = format("%s-master-%02d", var.prefix, count.index+1)
  config_drive = true
  image_name = var.image_nodes
  flavor_name = var.flavor_master
  key_pair = openstack_compute_keypair_v2.ssh_key.name
  user_data = data.template_cloudinit_config.nodes.rendered
  security_groups = ["default"]
  network { name = openstack_networking_network_v2.cluster_network.name }
}

resource "openstack_compute_instance_v2" "worker" {
  count = var.worker_count
  name = format("%s-worker-%02d", var.prefix, count.index+1)
  image_name = var.image_nodes
  flavor_name = var.flavor_worker
  key_pair = openstack_compute_keypair_v2.ssh_key.name
  user_data = data.template_cloudinit_config.nodes.rendered
  config_drive = true
  security_groups = ["default"]
  network { name = openstack_networking_network_v2.cluster_network.name }
}
