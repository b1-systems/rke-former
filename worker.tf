data "template_file" "cloud_config_worker" {
  count = var.worker_count
  template = file("${path.module}/template.d/cloud-config.yml.tpl")
  vars = {
    hostname = format("%s-worker-%02d", var.prefix, count.index+1)
    ssh_login_user = var.ssh_login_user
    ssh_pubkey = file(var.ssh_pubkey_file)
    hosts = fileexists(var.hosts) ? file(var.hosts) : ""
    trusted_ca_certs = fileexists(var.trusted_ca_certs) ? file(var.trusted_ca_certs) : ""
  }
}

data "template_cloudinit_config" "worker" {
  count = var.worker_count
  base64_encode = false
  gzip = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = data.template_file.cloud_config_worker[count.index].rendered
  }
}

resource "openstack_compute_instance_v2" "worker" {
  count = var.worker_count
  name = format("%s-worker-%02d", var.prefix, count.index+1)
  config_drive = true
  image_name = var.image_nodes
  flavor_name = var.flavor_worker
  key_pair = openstack_compute_keypair_v2.ssh_key.name
  user_data = data.template_cloudinit_config.worker[count.index].rendered
  availability_zone_hints = var.availability_zone_hints_compute[count.index % length(var.availability_zone_hints_compute)]
  network { port = openstack_networking_port_v2.worker[count.index].id }
}

resource "openstack_networking_port_v2" "worker" {
  count = var.worker_count
  name = format("%s-worker-%02d", var.prefix, count.index+1)
  dns_name = format("%s-worker-%02d", var.prefix, count.index+1)
  network_id = openstack_networking_network_v2.cluster_network.id
  security_group_ids = [
    openstack_networking_secgroup_v2.ssh.id,
    openstack_networking_secgroup_v2.docker_proxy.id
    ]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.cluster_network.id
  }
}
