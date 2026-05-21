# Phase 3 — Vault + ESO

**Date:** 2026-03-01

### Tasks

- [x] Deploy Vault (standalone, manual unseal, ingress + TLS)
- [x] Deploy External Secrets Operator
- [x] Bootstrap Vault: init, unseal, KV engine, Kubernetes auth
- [x] Wire ESO → Vault via ClusterSecretStore
- [x] Migrate Grafana admin password out of plaintext values into Vault

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

- **BUG-03** — kube-prometheus-stack large CRDs lost; Prometheus + Alertmanager pods down
  - Symptom: Forced syncs on the monitoring app (prune: true, OutOfSync due to floating `82.x.x` version) caused ArgoCD to prune large CRDs (prometheuses, alertmanagers, scrapeconfigs, etc.). ArgoCD then cannot recreate them — fails with `metadata.annotations: Too long` even with `ServerSideApply=true`, because ArgoCD's ServerSideApply syncOption does NOT apply to CRDs in Helm's `crds/` directory (those bypass the syncOption and use client-side apply).
  - Partial fix applied: `helm.skipCrds: true` added to `apps/monitoring.yaml`; CRDs manually restored via `helm template --include-crds | kubectl apply --server-side`.

- **DEBT-02** — Prometheus + Alertmanager pods restored. **RESOLVED.**
  - Root cause: Operator restarted before CRDs were restored, silently disabled Prometheus/Alertmanager controllers for that process lifetime.
  - Fix: Restart the prometheus-operator pod after CRDs are back. Operator re-discovers CRDs and reconciles CRs.
  - Guard rules added to CLAUDE.md: never force-sync Healthy+OutOfSync with prune; restart operator if CRs exist but no StatefulSets.

- **DEBT-03** — No /etc/hosts automation; ClusterIP must be manually updated after each `minikube delete`/`start`
  - Current mitigation: one-time manual entry using `kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'`
  - Future fix: post-bootstrap script that reads the ClusterIP and patches `/etc/hosts`, or dnsmasq wildcard rule for `*.homelab` pointing to the ClusterIP

- **DEBT-04** — No resource requests or limits on any workload
  - Risk: on a finite-memory VM (minikube), Prometheus + Grafana + Vault + SeaweedFS could OOM the node. Scheduler has no visibility.
  - Future fix: add `resources.requests` at minimum on Prometheus, Grafana, and Vault Helm values before Phase 4.
