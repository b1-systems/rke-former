# RKE-Former

Kubernetes on OpenStack with the help of Terraform and RancherKubernetesEngine (RKE)

## Requirements

- [Terraform (v0.12+)](https://www.terraform.io/downloads.html)
- [Rancher RKE (1.2.8)](https://github.com/rancher/rke/releases/tag/v1.2.8)
- [Kubernetes CLI (v1.20.6+)](https://downloadkubernetes.com)

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

## Use the kubeconfig

```shell
export KUBECONFIG=$PWD/kube_config_cluster.yml

# correct the API endpoint to loadbalancer
kubectl config set clusters.local.server $(terraform output k8s_api_url)

# list nodes
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

## Install Cinder CSI (cloud-provider-openstack)

Using Cinder CSI you can provision persistent volume claims right from Cinder.

Create Helm chart values file `values.yaml`.

```yaml
---
storageClass:
  delete:
    isDefault: true
secret:
  create: true
  enabled: true
  name: cloud-config
  data:
    cloud-config: |-
      [Global]
      tls-insecure = false
      auth-url = OPENSTACK_API_URL
      application-credential-id = ID
      application-credential-secret = SECRET
      [BlockStorage]
      ignore-volume-az = true
```

Add Helm repository for `cloud-provider-openstack´.

```shell
helm repo add cpo https://kubernetes.github.io/cloud-provider-openstack
```

Deploy Cinder CSI.

```shell
helm install -n kube-system cinder-csi cpo/openstack-cinder-csi -f values.yaml
```

## Links

- RancherKubernetesEngine (rke) [Docs](https://rancher.com/docs/rke/latest/)

## Contribute

Fork -> Patch -> Pull request -> Merge

## Author

- Thorsten Schifferdecker <schifferdecker@b1-systems.de>
- Uwe Grawert <grawert@b1-systems.de>

## License

[GPL-3](LICENSE)
