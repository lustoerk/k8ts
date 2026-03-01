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
| kube-prometheus-stack | `monitoring` | Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics | Metrics collection, dashboards, alerting infrastructure |

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

`minikube tunnel` runs as a launchd daemon (installed by `bootstrap/install-tunnel-daemon.sh`). It starts at boot as root — no manual terminal required. With the qemu2 driver, LoadBalancer EXTERNAL-IP stays as the service ClusterIP (not 127.0.0.1); `/etc/hosts` must use the ClusterIP.

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
| ~~Prometheus + Grafana~~ | ~~2~~ | ~~Metrics and dashboards~~ — **deployed Phase 2** |
| ~~SOPS~~ | ~~3~~ | ~~Secret encryption at rest in git~~ — **dropped; Vault+ESO covers this** |
| Vault + ESO | 3 | Centralized secrets management; migrate Grafana password as validation |
| Keycloak | 4 | Identity and SSO |
| GitLab | 5 | Self-hosted git remote (replaces GitHub), learning phase |
| GitLab Runner | 6+ | CI pipelines |
| Network Policies | TBD | Namespace-level traffic isolation; not critical pre-Keycloak/GitLab but worth adding in Phase 4/5 as blast-radius practice |
| Alertmanager receiver | TBD | Wire Alertmanager to a real destination (Slack webhook, email). Currently null receiver — alerts fire and are discarded. Planned as an add-on once Vault is stable (credentials for webhook can be stored in Vault). |
| Resource requests/limits | TBD | No CPU/memory requests set on any workload (DEBT-04). Required before adding Vault + Keycloak to avoid OOM on the minikube VM. |