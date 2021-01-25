# RKE-Former

Kubernetes on OpenStack with the help of Terraform and RancherKubernetesEngine (RKE)

## Requirements

- [Terraform (v0.12+)](https://www.terraform.io/downloads.html)
- [Rancher RKE (1.1.7)](https://github.com/rancher/rke/releases/tag/v1.1.7)
- [Kubernetes CLI (v1.18.8+)](https://downloadkubernetes.com)

## Export OpenStack api url and user password

Using `clouds.yaml`:

```shell
export OS_CLOUD=<section>
export TF_VAR_openstack_auth_url=$(openstack configuration show -c auth.auth_url -f value)
export TF_VAR_openstack_password=$(openstack configuration show -c auth.password -f value --unmask)
```

Using `openrc.sh`:

```shell
source openrc.sh
export TF_VAR_openstack_auth_url=$OS_AUTH_URL
export TF_VAR_openstack_password=$OS_PASSWORD
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
EOF
```

## Deploy Kubernetes Nodes on OpenStack-Cloud

```shell
terraform init
terraform apply -auto-approve
```

## Test SSH connection to bastion host

```shell
ssh -F ssh_config bastion
```

## Kubernetes Deployment via RKE

Before running _rke_ command make sure your ssh-agent is containing your
ssh-key, to allow _rke_ to connect to all hosts through the bastion host.

```shell
rke up
```

## Use The kubeconfig

```shell
export KUBECONFIG=$PWD/kube_config_cluster.yml

# correct the API endpoint to loadbalancer
kubectl config set clusters.local.server $(terraform output k8s_api_url)

# list nodes
kubectl get nodes --output wide
```

## Accessing K8s API and Ingress

_rke-former_ has created a load balancer and floating IP for the Kubernetes API
and the Ingress Service. Find the load balancers and corresponding floating IPs
in your Openstack project.

```shell
openstack loadbalancer list -c name -c vip_address
+-----------------+-------------+
| name            | vip_address |
+-----------------+-------------+
| rke-k8s-cluster | 10.0.10.180 |
| rke-ingress     | 10.0.10.37  |
+-----------------+-------------+
```

```shell
openstack floating ip list -c "Floating IP Address" -c "Fixed IP Address"
+---------------------+------------------+
| Floating IP Address | Fixed IP Address |
+---------------------+------------------+
| 10.49.170.213       | 10.0.10.37       |
| 10.49.170.182       | 10.0.10.180      |
+---------------------+------------------+
```

Create an Ingress and access the Ingress using the floating IP for the Ingress
load balancer.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - http:
      paths:
      - path: /my-app
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

The app is accessible at http://10.49.170.213/my-app

## Add x509 certificates to Kubernetes

If you need to add certificates to allow Kubernetes to accept connections
to the Openstack API, put your certificates into a file named `ca-certs.pem` and
place it into the root directory.

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

## Links

- RancherKubernetesEngine (rke) [Docs](https://rancher.com/docs/rke/latest/)
- K8spin - a Kubernetes Namespace for free, check it out [K8spin](https://k8spin.cloud/)

## Contribute

Fork -> Patch -> Pull request -> Merge

## Author

- Thorsten Schifferdecker <schifferdecker@b1-systems.de>
- Uwe Grawert <grawert@b1-systems.de>

## License

[GPL-3](LICENSE)
