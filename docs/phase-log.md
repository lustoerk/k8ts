# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)
- [Phase 3 — Vault + ESO](history/phase-3.md)
- [Phase 4 — Keycloak](history/phase-4.md)
- [Phase 4 Review — Professionalization](adrs/adr11-professionalization-roadmap.md)

---

## Phase 5 — Resource Limits & Requests `<-- current`

**Date:** 2026-03-01

### Tasks

- [x] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [x] Define and apply CPU/memory requests and limits for all Helm-managed services
- [x] Validate cluster stability under constrained resources
- [x] Update Grafana dashboards to visualize resource usage vs. limits

### Bugs / Unplanned Work

**BUG-01** SeaweedFS chart expects `resources` as a multiline string, not a map
- **Symptom:** ArgoCD ComparisonError on seaweedfs app — `wrong type for value; expected string; got map`.
- **Fix:** Changed `resources:` block to use `|` multiline string format, matching the chart's `nodeSelector` pattern.

**BUG-02** `vault-agent-injector` rolling update deadlocked on single-node cluster
- **Symptom:** New injector pod stuck `Pending` — default `requiredDuringSchedulingIgnoredDuringExecution` anti-affinity blocked it while old pod was still running.
- **Fix:** Added `affinity: ""` to `injector:` in vault values. Manually deleted old pod and stale ReplicaSets to unblock the rollout.

**BUG-03** `vault-0` resource limits not applied via ArgoCD sync — `OnDelete` update strategy
- **Symptom:** StatefulSet spec updated by ArgoCD but vault-0 pod kept running with `resources: {}`. Also, dataStorage PVC size mismatch (values: 5Gi, live PVC: 10Gi) blocked ArgoCD convergence.
- **Fix:** Patched StatefulSet directly (`kubectl patch`) to apply resources and clear anti-affinity. Manually deleted vault-0 to trigger recreation. Corrected `dataStorage.size` to 10Gi in values to match the immutable live PVC.

**BUG-04** `monitoring` Application third source not picked up until root app re-synced
- **Symptom:** Adding `infra/monitoring/manifests` path source to `apps/monitoring.yaml` had no effect — ArgoCD cluster Application object still had only 2 sources.
- **Fix:** Root App-of-Apps must be explicitly synced to propagate changes to child Application specs. Synced root app, then re-synced monitoring.

### Tech Debt

---

## Phase 6 — SeaweedFS Review & Integration

**Date:** TBD

### Tasks

- [ ] Enable S3 authentication (access key / secret key)
- [ ] Store S3 credentials in Vault, sync via ESO
- [ ] Enable SeaweedFS Prometheus metrics + add ServiceMonitor
- [ ] Build Grafana dashboard for SeaweedFS (capacity, request rate, latency)
- [ ] Expose SeaweedFS admin UI via ingress (`seaweedfs.homelab`)
- [ ] Evaluate Keycloak integration for admin UI access (OAuth2 proxy or native)
- [ ] Deploy a small test workload that reads/writes to the S3 endpoint
- [ ] Document S3 usage patterns for future workloads

### Bugs / Unplanned Work

### Tech Debt

---

## Phase 7 — Operational Hardening

**Date:** TBD

### Tasks

- [ ] Declarative CoreDNS — replace manual `hosts` patching with GitOps-managed ConfigMap
- [ ] Vault auto-unseal or break-glass procedure
- [ ] Document "Bootstrap from Zero" disaster recovery runbook
- [ ] Persistent storage — mount macOS host folders into minikube for data survival
- [ ] /etc/hosts automation (script or LaunchAgent)

### Bugs / Unplanned Work

### Tech Debt

---

## Phase 8 — New Applications (TBD)

**Date:** TBD

### Tasks

- [ ] Forgejo or GitLab (self-hosted SCM + CI, Keycloak SSO)
- [ ] AI/ML workload using SeaweedFS S3 for model/data storage
- [ ] Additional Keycloak-integrated services as needed

### Bugs / Unplanned Work

**BUG-09** ArgoCD OIDC `invalid_scope: Invalid scopes: openid profile email groups`
- **Symptom:** ArgoCD OIDC login rejected by Keycloak with `invalid_scope` on the `groups` scope.
- **Fix:** Removed `groups` from `requestedScopes` in `argocd-cm`. `groups` is a Keycloak protocol mapper (JWT claim), not a registered OAuth scope. The claim is still injected into the ID token via `oidc-group-membership-mapper` on the `argocd` client, and RBAC continues to work via `scopes: '[groups]'` in `argocd-rbac-cm`.

### Tech Debt

