# b1dod2020-kubernetes-deployment

a full stack of Deployments : Kubernetes on OpenStack with the help of terraform and rke - called rke-former

# Steps

1) Get needed binaries

- terraform (v0.12+) [Download](https://www.terraform.io/downloads.html)
- rke (1.0.1) [Download](https://github.com/rancher/rke/releases/tag/v1.0.1)
- kubernetes-cli (v1.16.3+) [Overview of KubeBinaries](https://downloadkubernetes.com)

2) Get the code

```bash=
git clone git@git.intern.b1-systems.de:schifferdecker/b1dod2020-kubernetes-deployments.git rke-former
cd $_
```

3) Setup credentials 

- OpenStack
  Populate the OpenStack files clouds.yaml, secure.yaml and export the clouds var

  ```bash=
  export OS_CLOUD=<section>
  ```

- Generate ssh-keys for deployment

  ```bash=
  ssh-keygen -f terraform
  ```

4) Start the terraforming

```
# init and download terraform plugins
terraform init [<opts>]

# set var for Kubernetes provider plugin
export TF_VAR_openstack_auth_url=$(openstack configuration show -c auth.auth_url -f value)
export TF_VAR_openstack_password=$(openstack configuration show -c auth.password -f value --unmask)

# render the plan and graph 
terraform plan [<opts>]

# deploy
terraform apply [<opts]
```

5) Kubernetes Deployment via rke

The terraform plan deploy all needed object in our infrastructure and template a config for the 
kubernetes.

```bash=
cd rke
rke up
# wait some minutes, a good chance to fetch a cup of coffee
```

6) Use the kubeconfig

```bash=
export KUBECONFIG=$PWD/k/kube_config_cluster.yml
kubectl get nodes --output wide
```

# Links

- RancherKubernetesEngine (rke) [Docs](https://rancher.com/docs/rke/latest/)
- K8spin - a Kubernetes Namespace for free, check it out [K8spin](https://k8spin.cloud/)


# Contribute

Fork -> Patch -> Pull request -> Merge

# Author

`Thorsten Schifferdecker <schifferdecker@b1-systems.de>`

# License

`GPL-3`

