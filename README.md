# k8ts — The macOS Enterprise Homelab

A GitOps-driven, "Enterprise-Grade" Kubernetes cluster on `minikube` (qemu2).

This project aims to replicate a production-like environment (Vault, Keycloak, SeaweedFS, OIDC) on a single-node macOS host for learning and testing.

---

## Status & Services

| Service | Hostname | Role | Status |
| :--- | :--- | :--- | :--- |
| **ArgoCD** | `argo.homelab` | GitOps Control Plane | Ready |
| **Grafana** | `graf.homelab` | Metrics & Dashboards | Ready (Keycloak SSO) |
| **Vault** | `vault.homelab` | Secret Management | Ready (manual unseal) |
| **Keycloak** | `keycloak.homelab` | Identity (OIDC) | Ready |
| **SeaweedFS** | `s3.homelab` | S3-Compatible Storage | Minimal (no auth, no monitoring) |
| **Prometheus** | (cluster-internal) | Metrics Collection | Ready |
| **cert-manager** | — | TLS (self-signed CA) | Ready |
| **ingress-nginx** | — | Ingress Controller | Ready |
| **ESO** | — | Vault-to-K8s Secret Sync | Ready |
| **Redis Operator** | (cluster-internal) | In-Cluster Redis | Ready |

---

## Completed Phases

### Phase 0 — Prerequisites & Scaffold
Installed core tools (minikube, helm, kubectl, qemu, socket_vmnet). Created GitHub repo. Scaffolded directory structure, ArgoCD Application manifests, Helm values, ADRs 01-07, bootstrap script, and CLAUDE.md.

### Phase 1 — Bootstrap & Initial Sync
Bootstrapped minikube cluster and ArgoCD. Deployed cert-manager, ingress-nginx, and SeaweedFS via App-of-Apps. Resolved repo-creds, PAT auth, arm64 nodeSelector, and StatefulSet lifecycle bugs.

### Phase 2 — Monitoring (Prometheus + Grafana)
Deployed kube-prometheus-stack. Configured Grafana ingress + TLS at `graf.homelab`. Resolved arm64 compatibility and ArgoCD auto-discovery issues.

### Phase 3 — Vault + ESO
Deployed Vault (standalone, manual unseal) and External Secrets Operator. Bootstrapped Vault with KV engine and Kubernetes auth. Wired ESO ClusterSecretStore. Migrated Grafana admin password from plaintext to Vault. Resolved CRD size limits (ServerSideApply).

### Phase 4 — Keycloak SSO
Deployed Keycloak with realm import via init container (envsubst). Wired Grafana OAuth and ArgoCD OIDC. Resolved 8 bugs including in-cluster DNS, PKCE, issuer URL, and CoreDNS patching. Conducted architecture review (ADR-11).

### Phase 5 — Resource Limits & Requests
Enforced resource limits and requests across all workloads. Validated with CFS throttling tests and cluster-wide restart audit.

### Phase 6 — Redis Operator
Deployed OT-CONTAINER-KIT Redis Operator (v0.24.0). Registered 4 CRDs (Redis, RedisCluster, RedisReplication, RedisSentinel). Validated with smoke test.

---

## Roadmap

**Current phase:** See [`.scratch/LOG.md`](.scratch/LOG.md) for active session state.

Completed phases: [`docs/history/`](docs/history/)  
Forward roadmap: [`docs/phase-log.md`](docs/phase-log.md)

### Upcoming Phases (summary)

- **Phase 7** — SeaweedFS Review & Integration  
- **Phase 8** — Operational Hardening  
- **Phase 9** — New Applications

---

## Operations

### 1. Bootstrap
```sh
bash bootstrap/bootstrap.sh
```
The script handles `minikube` initialization, ArgoCD installation, and the initial "App-of-Apps" sync.

### 2. DNS (macOS)
The cluster uses `ingress-nginx` with `minikube tunnel`. Entries in `/etc/hosts` are required:
```sh
# Get the ingress ClusterIP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'

# Add to /etc/hosts
<ClusterIP> argo.homelab graf.homelab vault.homelab keycloak.homelab s3.homelab
```

### 3. Secrets
Managed via **HashiCorp Vault** and synchronized into Kubernetes Secrets using **External Secrets Operator (ESO)**.
- **Note:** Vault starts sealed on every cluster restart. To unseal:
  ```sh
  # Retrieve the two unseal keys from .secrets (git‑ignored)
  UNSEAL_KEY_1=$(grep 'Unseal Key 1' .secrets | awk '{print $4}')
  UNSEAL_KEY_2=$(grep 'Unseal Key 2' .secrets | awk '{print $4}')
  # Execute inside the Vault pod
  kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY_1
  kubectl exec -it vault-0 -n vault -- vault operator unseal $UNSEAL_KEY_2
  ```
  After the second key Vault will report `Sealed: false`. Store the keys securely (password manager) – they are required after any `minikube stop/start` or `minikube delete`.

---

## Key Documentation

- **[System Map](docs/understanding/system-map.md)** — Architectural overview of services.
- **[Architecture Decisions (ADRs)](docs/adrs/)** — The "Why" behind every tool choice.
- **[Phase Log](docs/phase-log.md)** — Historical record of work and technical debt.
- **[Professionalization Roadmap](docs/adrs/adr11-professionalization-roadmap.md)** — Outcomes of the Phase 4 Review.

---

## Stack

- **Runtime:** `minikube` (qemu2, arm64)
- **GitOps:** ArgoCD (App-of-Apps, wave-based sync)
- **Identity:** Keycloak (OIDC for Grafana + ArgoCD)
- **Secrets:** Vault + External Secrets Operator
- **Storage:** SeaweedFS (S3-compatible, hostPath backend)
- **TLS:** cert-manager (self-signed CA chain)
- **Monitoring:** kube-prometheus-stack (Prometheus + Grafana)
- **Ingress:** ingress-nginx
