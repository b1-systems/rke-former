### K8s Cluster Loadbalancer
resource "openstack_lb_loadbalancer_v2" "k8s_cluster" {
  name = "${var.prefix}-k8s-cluster"
  vip_subnet_id = openstack_networking_subnet_v2.cluster_network.id
  description = "Loadbalancer for Kubernetes Cluster"
}

resource "openstack_networking_floatingip_v2" "k8s_cluster" {
  pool = var.external_network_name
  port_id = openstack_lb_loadbalancer_v2.k8s_cluster.vip_port_id
  description = "Kubernetes Cluster (${var.prefix})"
}

### K8s API
resource "openstack_lb_listener_v2" "k8s_api" {
  name = "k8s-api"
  protocol = "TCP"
  protocol_port = var.kubernetes_api_port
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_cluster.id
}

resource "openstack_lb_pool_v2" "k8s_api" {
  name = "k8s-api"
  protocol = "TCP"
  lb_method = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8s_api.id
}

resource "openstack_lb_member_v2" "k8s_api" {
  count = var.master_count
  name = format("k8s-api-member-%02d", count.index+1)
  address = openstack_compute_instance_v2.master[count.index].access_ip_v4
  protocol_port = var.kubernetes_api_port
  pool_id = openstack_lb_pool_v2.k8s_api.id
  subnet_id = openstack_networking_subnet_v2.cluster_network.id
}

resource "openstack_lb_monitor_v2" "k8s_api" {
  name = "k8s-api"
  pool_id = openstack_lb_pool_v2.k8s_api.id
  type = "TCP"
  delay = 2
  timeout = 2
  max_retries = 2
}

### Ingress HTTP
resource "openstack_lb_listener_v2" "ingress_http" {
  name = "k8s-ingress-http"
  protocol = "TCP"
  protocol_port = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_cluster.id
}

resource "openstack_lb_pool_v2" "ingress_http" {
  name = "k8s-ingress-http"
  protocol = "TCP"
  lb_method = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.ingress_http.id
}

resource "openstack_lb_member_v2" "ingress_http" {
  count = var.worker_count
  address = openstack_compute_instance_v2.worker[count.index].access_ip_v4
  protocol_port = 80
  pool_id = openstack_lb_pool_v2.ingress_http.id
  subnet_id = openstack_networking_subnet_v2.cluster_network.id
}

resource "openstack_lb_monitor_v2" "ingress_http" {
  name = "k8s-ingress-http"
  pool_id = openstack_lb_pool_v2.ingress_http.id
  type = "TCP"
  delay = 2
  timeout = 2
  max_retries = 2
}

### Ingress HTTPS
resource "openstack_lb_listener_v2" "ingress_https" {
  name = "k8s-ingress-https"
  protocol = "TCP"
  protocol_port = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.k8s_cluster.id
}

resource "openstack_lb_pool_v2" "ingress_https" {
  name = "k8s-ingress-https"
  protocol = "TCP"
  lb_method = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.ingress_https.id
}

resource "openstack_lb_member_v2" "ingress_https" {
  count = var.worker_count
  name = format("k8s-ingress-https-member-%02d", count.index+1)
  address = openstack_compute_instance_v2.worker[count.index].access_ip_v4
  protocol_port = 443
  pool_id = openstack_lb_pool_v2.ingress_https.id
  subnet_id = openstack_networking_subnet_v2.cluster_network.id
}

resource "openstack_lb_monitor_v2" "ingress_https" {
  name = "k8s-ingress-https"
  pool_id = openstack_lb_pool_v2.ingress_https.id
  type = "TCP"
  delay = 2
  timeout = 2
  max_retries = 2
}

output "k8s_api_url" {
  value = format("https://%s:%s",
                 openstack_networking_floatingip_v2.k8s_cluster.address,
                 var.kubernetes_api_port)
}

output "k8s_ingress_url" {
  value = format("https://%s",
                 openstack_networking_floatingip_v2.k8s_cluster.address)
}
