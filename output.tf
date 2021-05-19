output "k8s_api_url" {
  value = format("https://%s:%s",
                 openstack_networking_floatingip_v2.k8s_cluster.address,
                 var.kubernetes_api_port)
}

output "k8s_ingress_url" {
  value = format("https://%s",
                 openstack_networking_floatingip_v2.ingress.address)
}
