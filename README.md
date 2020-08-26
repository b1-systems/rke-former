# RKE-Former

Kubernetes on OpenStack with the help of Terraform and Rancher RKE

## Requirements

- [Terraform (v0.12+)](https://www.terraform.io/downloads.html)
- [Rancher RKE (1.0.1)](https://github.com/rancher/rke/releases/tag/v1.0.1)
- [Kubernetes CLI (v1.16.3+)](https://downloadkubernetes.com)

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

```shell
cat > terraform.tfvars <<EOF
prefix = "rke"
master_count = 1
worker_count = 3
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
