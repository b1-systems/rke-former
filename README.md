# RKE-Former

Kubernetes on OpenStack with the help of Terraform and RancherKubernetesEngine (RKE)

## Requirements

- [Terraform (v0.14+)](https://www.terraform.io/downloads.html)

## Export OpenStack api url and user password

Using `clouds.yaml`:

```shell
export OS_CLOUD=<section>
```

Using `openrc.sh` or Keystone app-credentials:

```shell
source openrc.sh
```

## Basic Configuration

Set the number of Kubernetes master and worker nodes that should be deployed.
Set the name of the external network you want to use for accessing the cluster.

```shell
cat > terraform.tfvars <<EOF
prefix = "rke"
master_count = 1
worker_count = 3
external_network_name = "external"
ssh_identity_file = "~/.ssh/YOUR_SSH_KEY"
ssh_pubkey_file = "~/.ssh/YOUR_SSH_KEY_PUB"
availability_zone_hints_compute = ["nova"]
availability_zone_hints_network = ["nova"]
EOF
```

## Deploy Kubernetes Nodes on OpenStack-Cloud

```shell
terraform init
terraform apply -auto-approve
```

## Run RKE on the bastion host

```shell
scp -F ssh_config cluster.yml bastion:
ssh -F ssh_config bastion
rancher@bastion:~$ rke up
```

## Use the kubeconfig

```shell
export KUBECONFIG=$PWD/kube_config_cluster.yml
```

When using the kubeconfig from a host outside of the OpenStack project,
correct the API endpoint to use the loadbalancer address.

```shell
kubectl config set clusters.local.server $(terraform output k8s_api_url)
```

## list nodes

```shell
kubectl get nodes --output wide
```

## Accessing K8s API and Ingress

_rke-former_ has created a load balancer and floating IP for the Kubernetes API
and the Ingress Service. You can find the load balancers and corresponding
floating IPs in your Openstack project. Or use `terraform output` to print the
URLs.

```shell
terraform output k8s_api_url
```

```shell
terraform output k8s_ingress_url
```

Create an Ingress and access the Ingress using the floating IP for the Ingress
load balancer.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: my-app.example.com
        http:
          paths:
          - path: /
            pathType: ImplementationSpecific
            backend:
              serviceName: my-app
              servicePort: 8080
  tls:
    - secretName: my-app.example.com-tls
      hosts:
        - my-app.example.com
```

The app is accessible at https://K8S_INGRESS_URL/my-app

## Add /etc/hosts file

Add a manually crafted hosts file named `hosts` into the root directory, to
make it available on the cluster nodes.

## Define additional routes to networks

Additional network routes are defined in a map `additional_routes`.
The `router_ip_address` is an IP from the k8s cluster network defined
by the network cidr at variable `cluster_network_cidr`. Make sure the
IP is not taken already. `network_id` defines the id of the neutron network
you want to connect to. A router will be created automatically.
`network_cidr` is the network cidr of the network you want to reach.

terraform.tfvars:
```yaml
additional_routes = {
  "ceph-frontend" = {
    router_ip_address = "10.0.10.5"
    network_id = "a49aae6e-d988-44ae-a4c2-980b106b6a61"
    network_cidr = "172.16.100.0/24"
  }
}
```

## Install Cloud Provider Openstack

### Create `cloud-config` secret

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: cloud-config
  namespace: kube-system
type: Opaque
stringData:
  cloud.conf: |
    [Global]
    tls-insecure = false
    application-credential-id = APP_ID
    application-credential-secret = APP_SECRET
    auth-url = https://YOUR_OPENSTACK_CLOUD:5000

    [Networking]
    public-network-name = external

    [LoadBalancer]
    create-monitor = true
    floating-network-id = EXTERNAL_NET_ID
    subnet-id = INTERNAL_SUBNET_ID

    [BlockStorage]
    ignore-volume-az = true
```

### Apply Openstack Cloud Controller Manager manifests

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/cloud-controller-manager-roles.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/cloud-controller-manager-role-bindings.yaml
```

* Download the DaemonSet manifest

```shell
curl -LO https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/controller-manager/openstack-cloud-controller-manager-ds.yaml
```

* Set the tolerations

```yaml
tolerations:
  - key: node.cloudprovider.kubernetes.io/uninitialized
    value: "true"
    effect: NoSchedule
  - key: node-role.kubernetes.io/controlplane
    effect: NoSchedule
  - key: node-role.kubernetes.io/etcd
    effect: NoExecute
```

* Remove the node selector

```shell
nodeSelector:
  node-role.kubernetes.io/master: ""
```

* Apply the DaemonSet manifest

```shell
kubectl apply -f openstack-cloud-controller-manager-ds.yaml
```

### Deploy Cinder CSI

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-controllerplugin.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin-rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/cinder-csi-nodeplugin.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/csi-cinder-driver.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/cloud-provider-openstack/master/manifests/cinder-csi-plugin/csi-secret-cinderplugin.yaml
```

## Links

- RancherKubernetesEngine (rke) [Docs](https://rancher.com/docs/rke/latest/)

## Contribute

Fork -> Patch -> Pull request -> Merge

## Author

- Thorsten Schifferdecker
- Uwe Grawert

## License

[GPL-3](LICENSE)
