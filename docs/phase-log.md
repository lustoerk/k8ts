# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)

---

## Phase 3 — Vault + ESO

**Date:** 2026-03-01

### Tasks

- [x] Deploy Vault (standalone, manual unseal, ingress + TLS)
- [x] Deploy External Secrets Operator
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

- **BUG-03** — kube-prometheus-stack large CRDs lost; Prometheus + Alertmanager pods down
  - Symptom: Forced syncs on the monitoring app (prune: true, OutOfSync due to floating `82.x.x` version) caused ArgoCD to prune large CRDs (prometheuses, alertmanagers, scrapeconfigs, etc.). ArgoCD then cannot recreate them — fails with `metadata.annotations: Too long` even with `ServerSideApply=true`, because ArgoCD's ServerSideApply syncOption does NOT apply to CRDs in Helm's `crds/` directory (those bypass the syncOption and use client-side apply).
  - Partial fix applied: `helm.skipCrds: true` added to `apps/monitoring.yaml`; CRDs manually restored via `helm template --include-crds | kubectl apply --server-side`.
  - Remaining issue: Prometheus-operator admission webhook has a stale cert (caBundle in ValidatingWebhookConfiguration doesn't match the cert in the admission secret). Operator cannot reconcile Prometheus/Alertmanager CRs. StatefulSets not created. prom.homelab and alman.homelab return 503.
  - Not blocking Phase 3. Deferred — see DEBT-02.

- **DEBT-03** — No /etc/hosts automation; ClusterIP must be manually updated after each `minikube delete`/`start`
  - Current mitigation: one-time manual entry using `kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.clusterIP}'`
  - Future fix: post-bootstrap script that reads the ClusterIP and patches `/etc/hosts`, or dnsmasq wildcard rule for `*.homelab` pointing to the ClusterIP

- **DEBT-04** — No resource requests or limits on any workload
  - Risk: on a finite-memory VM (minikube), Prometheus + Grafana + Vault + SeaweedFS could OOM the node. Scheduler has no visibility.
  - Future fix: add `resources.requests` at minimum on Prometheus, Grafana, and Vault Helm values before Phase 4.

- **DEBT-02** — Prometheus + Alertmanager pods restored. **RESOLVED.**
  - Root cause (clarified): The operator restarted **before** the CRDs were restored. On startup it logged `resource "prometheuses" not installed in the cluster` and disabled those controllers permanently for that process lifetime. CRDs came back later but operator never re-detected them.
  - The stale caBundle was a red herring — both webhooks are `failurePolicy: Ignore`, so TLS mismatches were noise.
  - Fix: `kubectl patch validatingwebhookconfiguration` to align caBundle with secret CA (cosmetic cleanup), then `kubectl delete pod` on the operator to force a restart. Operator re-discovered CRDs, reconciled CRs, StatefulSets up in 33s. prom.homelab and alman.homelab healthy.
  - Guard rule learned: **Never force-sync a Healthy+OutOfSync app with prune: true.** The monitoring OutOfSync was benign (floating chart version). Stop after 2 failed recovery attempts — declare debt and move on.
  - Guard rule learned: kube-prometheus-stack CRD size issue is the same class as ESO BUG-01. Correct fix on first encounter: `kubectl apply --server-side --include-crds` + `helm.skipCrds: true`. Do not fight ArgoCD for more than one attempt.
  - Guard rule learned: If prometheus-operator starts before its CRDs are installed, it silently disables Prometheus/Alertmanager controllers. Symptom: CRs exist, no StatefulSets, no reconciliation log entries. Fix: restart the operator pod.
