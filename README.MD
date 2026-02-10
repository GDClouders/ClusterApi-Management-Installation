# CusterApi Management Installation
# Cluster API — Management Installation

This repository contains templates and instructions to create a temporary local management
cluster using Kind and then provision tenant clusters on Proxmox using the Cluster API
provider for Proxmox.

Security note: never commit tokens, secrets, or private keys. Use an ignored `.env` file
or a secrets manager. A `.env.example` file is provided with placeholders—copy it to
`.env` and fill in real values locally.

## Prerequisites

- `kind` (local Kubernetes cluster)
- `kubectl`
- `clusterctl`
- Access to a Proxmox instance and the `cluster-api-provider-proxmox`

Reference docs:

- Kind quickstart: https://kind.sigs.k8s.io/docs/user/quick-start/
- Cluster API quickstart: https://cluster-api.sigs.k8s.io/user/quick-start

## Workflow summary

1. Create a local Kind management cluster.
2. Initialize Cluster API providers (infrastructure provider: Proxmox).
3. Generate and apply cluster templates to provision tenant clusters on Proxmox.
4. Move the management role from the local Kind cluster to the new management cluster on Proxmox.

## Using environment variables

There is a `.env.example` file in the repo with all sensitive and environment-specific
placeholders. Copy it to `.env`, edit values, then load it before running commands:

```bash
cp .env.example .env
# edit .env, then
source .env
```

Do not commit `.env`; `.env` is ignored via `.gitignore`.

## Example: creating the management cluster (Kind)

Install `kind` (example for Linux x86_64):

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind create cluster
```

## Install Cluster API

Install `clusterctl` (example):

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.11.3/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
clusterctl version
```

## Generating and applying a cluster on Proxmox

After setting up provider credentials in your local `.env` and sourcing it,
generate and apply a cluster manifest for the `management` namespace:

```bash
kubectl create namespace management
clusterctl generate cluster manager-dev \
  --kubernetes-version v1.34.1 \
  --control-plane-machine-count=3 \
  --worker-machine-count=3 \
  --target-namespace management > manager-dev.yaml

kubectl apply -f manager-dev.yaml

# Save the generated kubeconfig for the new management cluster
clusterctl get kubeconfig manager-dev -n management > ~/.kube/configs/manager-dev.kubeconfig
export KUBECONFIG=~/.kube/configs/manager-dev.kubeconfig
```

## CNI example (Calico)

```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.1/manifests/operator-crds.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.31.1/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.31.1/manifests/custom-resources.yaml
kubectl apply -f custom-resources.yaml
```

## Moving the management role

When the Proxmox management cluster is healthy, move the Cluster API management
objects to the new cluster:

```bash
unset KUBECONFIG
clusterctl move --to-kubeconfig=~/.kube/configs/manager-dev.kubeconfig --namespace management
```

## Variables and secrets

All sensitive values (tokens, secrets, SSH private keys) should be stored locally in
`.env`. See `.env.example` for the full list of variables used by templates in this repo.

## Contributing and commit types

| Type  | Content                                | Example                                         |
|-------|----------------------------------------|-------------------------------------------------|
| feat  | New feature                            | feat: add proxmox provider example               |
| fix   | Bug fix                                | fix: correct template variable                  |
| docs  | Documentation changes                  | docs: update README                              |
| chore | Repository maintenance/config          | chore: add .gitignore                            |

