# System Map

One-page reference for what's running, where, and what it provides.
For decisions, see `docs/adrs/`. For current phase state, see `docs/contextblock.md`.

---

## Services

| Service | Namespace | Manages | Provides |
|---------|-----------|---------|----------|
| ArgoCD | `argocd` | All child Applications | GitOps control plane — syncs cluster to git |
| cert-manager | `cert-manager` | CRDs: Certificate, Issuer, ClusterIssuer | TLS certificate lifecycle |
| cert-manager-issuers | `cert-manager` | ClusterIssuer resources | The self-signed CA chain used by all ingress TLS |
| ingress-nginx | `ingress-nginx` | IngressClass: nginx | HTTP/HTTPS routing into the cluster |
| seaweedfs | `seaweedfs` | StatefulSets, StorageClass | S3-compatible object storage |

---

## TLS Chain

```
selfsigned-bootstrap (ClusterIssuer)
  └── homelab-ca (Certificate — the root CA)
        └── homelab-ca-issuer (ClusterIssuer — used by all Ingress TLS)
```

The CA cert is trusted on macOS via the system keychain. All ingress TLS certificates
are issued by `homelab-ca-issuer`. See `infra/cert-manager-issuers/` for the manifests.

---

## Traffic Path (inbound request)

```
browser
  → minikube tunnel (exposes LoadBalancer IP on macOS)
    → ingress-nginx (LoadBalancer service, routes by host/path)
      → Service → Pod
```

`minikube tunnel` must be running in a separate terminal for external access.

---

## Storage

Two storage tiers, different purposes:

- **minikube hostPath** (`standard` StorageClass): used by platform components that need PVCs (e.g. ArgoCD, Prometheus). Backed by the minikube VM's local disk.
- **SeaweedFS** (`seaweedfs` StorageClass): S3-compatible object storage, available as a separate StorageClass. Used for workloads that need blob/object storage.

---

## What's Deferred

Not running yet, planned for future phases:

| Tool | Phase | Role |
|------|-------|------|
| Prometheus + Grafana | 2 | Metrics and dashboards |
| SOPS | 3 | Secret encryption at rest in git |
| Vault + ESO | 4 | Dynamic secrets |
| GitLab | 5 | Self-hosted git remote (replaces GitHub) |
| GitLab Runner | 6 | CI pipelines |
| Keycloak | 7 | Identity and SSO |