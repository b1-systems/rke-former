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
Set the name of the external network you want to use to access the cluster.

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

Before running _rke_ command make sure your ssh-key is added to your ssh-agent,
so _rke_ can connect to all hosts through the bastion host.

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
