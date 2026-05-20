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

---

## Roadmap

### Phase 5 — Resource Limits & Requests `<-- current`
Implement DEBT-04: production-grade resource management across all workloads.

- [ ] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [ ] Define and apply CPU/memory requests and limits for all Helm-managed services
- [ ] Validate cluster stability under constrained resources
- [ ] Update Grafana dashboards to visualize resource usage vs. limits

### Phase 6 — SeaweedFS Review & Integration
Bring SeaweedFS from "deployed but unused" to a fully integrated, tested storage service.

- [ ] Enable S3 authentication (access key / secret key)
- [ ] Store S3 credentials in Vault, sync via ESO
- [ ] Enable SeaweedFS Prometheus metrics + add ServiceMonitor
- [ ] Build Grafana dashboard for SeaweedFS (capacity, request rate, latency)
- [ ] Expose SeaweedFS admin UI via ingress (`seaweedfs.homelab`)
- [ ] Evaluate Keycloak integration for admin UI access (OAuth2 proxy or native)
- [ ] Deploy a small test workload that reads/writes to the S3 endpoint
- [ ] Document S3 usage patterns for future workloads (AI model storage, backups)

### Phase 7 — Operational Hardening
Close remaining tech debt and improve day-to-day operations.

- [ ] Declarative CoreDNS — replace manual `hosts` patching with GitOps-managed ConfigMap
- [ ] Vault auto-unseal or break-glass procedure
- [ ] Document "Bootstrap from Zero" disaster recovery runbook
- [ ] Persistent storage — mount macOS host folders into minikube for data survival across `minikube delete`
- [ ] /etc/hosts automation (script or LaunchAgent)

### Phase 8 — New Applications (TBD)
Only after the platform is hardened. Candidates:

- [ ] Forgejo or GitLab (self-hosted SCM + CI, Keycloak SSO)
- [ ] AI/ML workload using SeaweedFS S3 for model/data storage
- [ ] Additional Keycloak-integrated services as needed

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
