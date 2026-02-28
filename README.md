# k8ts

Single-tenant homelab Kubernetes cluster. GitOps via ArgoCD on minikube (macOS, qemu2 driver).

---

## Day 0 — Prerequisites

Install the following tools before running the bootstrap script.

```sh
# Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Core tools
brew install minikube helm kubectl

# qemu2 driver dependencies
brew install qemu socket_vmnet
```

Configure `socket_vmnet` per the [minikube qemu2 driver docs](https://minikube.sigs.k8s.io/docs/drivers/qemu/) before continuing.

Verify minikube can start with the qemu2 driver:

```sh
minikube start --driver=qemu2
minikube delete
```

Optional:

```sh
brew install argocd   # ArgoCD CLI for inspecting sync status
```

---

## Day 1 — Bootstrap

```sh
bash bootstrap/bootstrap.sh
```

The script will:

1. Start minikube (qemu2, 16 GB RAM, 4 CPUs, 50 GB disk)
2. Enable the metrics-server addon
3. Install ArgoCD via Helm into the `argocd` namespace
4. Wait for `argocd-server` to become available
5. Prompt you to create the GitHub repo-creds Secret (PAT required)
6. Apply the root App-of-Apps (`bootstrap/root-app.yaml`)

ArgoCD then syncs `apps/` automatically. Everything from this point is GitOps.

After bootstrap, access the ArgoCD UI:

```sh
minikube service argocd-server -n argocd
```

---

## Sync Wave Order

| Wave | Application           |
|------|-----------------------|
| 0    | cert-manager          |
| 1    | cert-manager-issuers  |
| 1    | ingress-nginx         |
| 2    | seaweedfs             |

cert-manager CRDs must be registered before issuers can be applied.
Issuers are a separate ArgoCD Application to avoid CRD ordering races.

---

## DNS on macOS

Services are exposed via ingress on `*.k8s.local`. Add entries to `/etc/hosts`
using `minikube ip` (qemu2 returns a VM IP, not 127.0.0.1):

```sh
echo "$(minikube ip) argocd.k8s.local seaweedfs.k8s.local filer.k8s.local" \
  | sudo tee -a /etc/hosts
```

Run `minikube tunnel` in a separate terminal for LoadBalancer services (ingress-nginx).

---

## Repo Structure

```
apps/       # ArgoCD Application manifests (App-of-Apps)
bootstrap/  # bootstrap.sh and root-app.yaml (run once, not GitOps)
infra/      # Helm values and raw manifests per service
docs/       # ADRs, context block, repo structure notes
```

See `docs/repo-structure.md` for full layout.
See `docs/adrs/` for architecture decisions.

---

## Stack

| Component        | Role                              |
|------------------|-----------------------------------|
| minikube (qemu2) | Local Kubernetes cluster          |
| ArgoCD           | GitOps controller                 |
| cert-manager     | TLS certificate management        |
| ingress-nginx    | Ingress controller                |
| SeaweedFS        | Distributed object/block storage  |

---

## Deferred / Future Phases

- Monitoring (kube-prometheus-stack)
- SOPS secret encryption
- Vault + External Secrets Operator
- Self-hosted GitLab (migrate from GitHub)
- Keycloak (OIDC for ArgoCD, GitLab, Grafana)
