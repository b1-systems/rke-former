resource "openstack_compute_keypair_v2" "ssh_key" {
  name = "${var.prefix}-ssh_key"
  public_key = file(var.ssh_pubkey_file)
}
