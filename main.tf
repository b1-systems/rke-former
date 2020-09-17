terraform {
  required_version = ">= 0.12"
}

provider "openstack" {
  insecure = true
  use_octavia = true
}

data "openstack_identity_auth_scope_v3" "scope" {
  name = "scope"
}
