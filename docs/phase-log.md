# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)

---

## Phase 3 — Vault + ESO

**Date:** TBD (restarting fresh)

### Tasks

- [ ] Deploy Vault (standalone, manual unseal, ingress + TLS)
- [ ] Deploy External Secrets Operator
- [ ] Bootstrap Vault: init, unseal, KV engine, Kubernetes auth
- [ ] Wire ESO → Vault via ClusterSecretStore
- [ ] Migrate Grafana admin password out of plaintext values into Vault

### Bugs / Unplanned Work

- **BUG-01** — ESO `SecretStore` and `ClusterSecretStore` CRDs silently skipped by ArgoCD
  - Symptom: ESO controller crashes with `no matches for kind "ClusterSecretStore" in version "external-secrets.io/v1"`. CRDs present in chart but missing from cluster.
  - Cause: CRD schemas exceed `kubectl apply` annotation size limit; ArgoCD drops them silently with client-side apply.
  - Fix: `ServerSideApply=true` in `apps/external-secrets.yaml` syncOptions. Must also refresh root app first so the Application object itself is updated before re-syncing ESO.

### Tech Debt

- **DEBT-01** — Hostname-based ingress implemented as unplanned prerequisite work before Phase 3
  - minikube tunnel launchd daemon (`bootstrap/install-tunnel-daemon.sh`) — run once after bootstrap
  - ArgoCD server ingress (`infra/argocd/ingress.yaml`, `apps/argocd-ingress.yaml`, wave 1)
  - Prometheus ingress added to `infra/monitoring/values.yaml`
  - /etc/hosts one-time manual step: `10.107.140.105 argo.homelab prom.homelab graf.homelab alman.homelab s3.homelab`
    (ClusterIP of ingress-nginx-controller; stable for service lifetime; see BUG-02)

- **BUG-02** — /etc/hosts must use ingress-nginx ClusterIP, not 127.0.0.1, with qemu2 driver
  - Symptom: `curl: (7) Failed to connect to argo.homelab port 443` despite tunnel running.
  - Cause: With the qemu2 driver, `minikube tunnel` routes the cluster CIDR (`10.96.0.0/12`) via the VM IP — LoadBalancer services keep their ClusterIP as EXTERNAL-IP. The Docker driver routes to `127.0.0.1` instead.
  - Fix: `/etc/hosts` entry must use the ingress-nginx ClusterIP (`kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'`), not `127.0.0.1`.
