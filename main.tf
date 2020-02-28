terraform {
  required_version = ">= 0.12"
}

provider "openstack" {}

data "openstack_identity_auth_scope_v3" "scope" {
  name = "scope"
}
