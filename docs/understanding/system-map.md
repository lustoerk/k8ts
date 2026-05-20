# System Map

One-page reference for what's running, where, and what it provides.
For decisions, see `docs/adrs/`. For current phase state, see `.scratch/LOG.md`.

---

## Services

| Service | Namespace | Manages | Provides |
|---------|-----------|---------|----------|
| ArgoCD | `argocd` | All child Applications | GitOps control plane — syncs cluster to git |
| argocd-ingress | `argocd` | Ingress for ArgoCD UI | TLS-terminated access at `argo.homelab` |
| cert-manager | `cert-manager` | CRDs: `Certificate`, `Issuer`, `ClusterIssuer` | TLS certificate lifecycle |
| cert-manager-issuers | `cert-manager` | `ClusterIssuer` resources | The self-signed CA chain used by all ingress TLS |
| ingress-nginx | `ingress-nginx` | IngressClass: `nginx` | HTTP/HTTPS routing into the cluster |
| seaweedfs | `seaweedfs` | StatefulSets, `seaweedfs` StorageClass | S3-compatible object storage |
| seaweedfs-ingress | `seaweedfs` | Ingress for S3/admin endpoints | TLS-terminated access at `s3.homelab` |
| monitoring (kube-prometheus-stack) | `monitoring` | Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics | Metrics collection, dashboards, alerting infrastructure |
| vault | `vault` | StatefulSet, PVC | Centralized secrets store; KV v2 at `secret/`; Kubernetes auth for ESO |
| external-secrets | `external-secrets` | CRDs: `ExternalSecret`, `ClusterSecretStore` | Syncs secrets from Vault into Kubernetes Secrets |
| vault-config | cluster-scoped + `monitoring` | `ClusterSecretStore`, `ExternalSecret` | Wires ESO to Vault; manages per-service ExternalSecrets. **Manual-sync only** — must not auto-sync before Vault is unsealed. |
| keycloak | `keycloak` | StatefulSet (Keycloak + PostgreSQL) | OIDC/OAuth2 SSO provider for all homelab services |
| keycloak-config | `keycloak` + `monitoring` + `argocd` | `ExternalSecret`s (client secrets) | Distributes Keycloak client secrets from Vault to consumer namespaces |

---

## TLS Chain

```
selfsigned-bootstrap   (ClusterIssuer — bootstrap only)
  └── homelab-ca       (Certificate in cert-manager ns — root CA, stored in Secret homelab-ca-tls)
        └── homelab-ca (ClusterIssuer — used by all ingress TLS)
```

The `Certificate` and the issuing `ClusterIssuer` share the name `homelab-ca`; they are different Kubernetes resource kinds. The CA cert is trusted on macOS via the system keychain. Manifests live in `infra/cert-manager-issuers/`.

---

## Traffic Path (inbound request)

```
browser
  → minikube tunnel              (exposes LoadBalancer IP on macOS)
    → ingress-nginx               (LoadBalancer service, routes by host/path)
      → Service → Pod
```

`minikube tunnel` runs as a launchd daemon (installed by `bootstrap/install-tunnel-daemon.sh`). It starts at boot as root — no manual terminal required. With the qemu2 driver, LoadBalancer `EXTERNAL-IP` stays as the service ClusterIP (not 127.0.0.1); `/etc/hosts` must use the ClusterIP.

---

## Storage

Two tiers, different purposes:

- **minikube hostPath** (`standard` StorageClass) — used by platform components that need PVCs (Vault, Prometheus, Keycloak PostgreSQL). Backed by the minikube VM's local disk. **Not persistent across `minikube delete`** (open debt — Phase 8).
- **SeaweedFS** (`seaweedfs` StorageClass) — S3-compatible object storage, available as a separate StorageClass. Reserved for workloads that need blob/object storage.

---

## Deployment Status

| Service | Phase | Status |
|---------|-------|--------|
| ArgoCD | 1 | Running |
| cert-manager (+ issuers) | 1 | Running |
| ingress-nginx | 1 | Running |
| SeaweedFS | 1 | Running (no auth, no monitoring — full review in Phase 7) |
| monitoring | 2 | Running (Application shows `OutOfSync/Healthy` permanently — known ArgoCD quirk with multi-source floating chart version; ignore) |
| Vault + ESO | 3 | Running (manual unseal on every cluster restart) |
| Keycloak (+ config) | 4 | Running (Grafana + ArgoCD SSO live) |
| Resource limits & requests | 5 | **In progress** — re-opened |

## Deferred

| Tool | Phase | Role |
|------|-------|------|
| Redis Operator | 6 | First application-layer workload |
| SeaweedFS full integration (auth, metrics, dashboard, ingress hardening) | 7 | Make SeaweedFS production-grade |
| Declarative CoreDNS | 8 | Replace manual `hosts` patching with GitOps-managed ConfigMap |
| Vault auto-unseal / break-glass | 8 | Eliminate the manual-unseal step on cluster restart |
| Persistent host-folder mounts | 8 | Survive `minikube delete` |
| `/etc/hosts` automation | 8 | LaunchAgent or script |
| Network Policies | TBD | Namespace-level traffic isolation; blast-radius practice |
| Alertmanager receiver | TBD | Currently null receiver — alerts fire and are discarded |
| GitLab / Forgejo + Runner | 9 | Self-hosted SCM + CI, Keycloak SSO |

## Dropped

- **SOPS** — superseded by Vault + ESO (decision in Phase 3).
- **GitLab migration of this repo** — keeping on GitHub for now (ADR-02).