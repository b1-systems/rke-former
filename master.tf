data "template_file" "cloud_config_master" {
  count = var.master_count
  template = file("${path.module}/template.d/cloud-config.yml.tpl")
  vars = {
    hostname = format("%s-master-%02d", var.prefix, count.index + 1)
    ssh_login_user = var.ssh_login_user
    ssh_pubkey = file(var.ssh_pubkey_file)
    hosts = fileexists(var.hosts) ? file(var.hosts) : ""
    certificates = fileexists(var.certificates) ? file(var.certificates) : ""
  }
}

data "template_cloudinit_config" "master" {
  count = var.master_count
  base64_encode = false
  gzip = false
  part {
    filename = "init.cfg"
    content_type = "text/cloud-config"
    content = data.template_file.cloud_config_master[count.index].rendered
  }
}

resource "openstack_compute_instance_v2" "master" {
  count = var.master_count
  name = format("%s-master-%02d", var.prefix, count.index + 1)
  config_drive = true
  image_name = var.image_nodes
  flavor_name = var.flavor_master
  key_pair = openstack_compute_keypair_v2.ssh_key.id
  user_data = data.template_cloudinit_config.master[count.index].rendered
  availability_zone_hints = var.availability_zone_hints_compute[count.index % length(var.availability_zone_hints_compute)]
  network { uuid = openstack_networking_network_v2.cluster_network.id }
  security_groups = [ "default",
                      openstack_networking_secgroup_v2.k8s_api.id,
                      openstack_networking_secgroup_v2.k8s_ingress.id,
                      openstack_networking_secgroup_v2.k8s_nodeport_range.id
                    ]
}
