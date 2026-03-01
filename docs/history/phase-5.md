# Phase 5 — Resource Limits & Requests

**Date:** 2026-03-01

## Tasks

- [x] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [x] Define and apply CPU/memory requests and limits for all Helm-managed services
- [x] Validate cluster stability under constrained resources
- [x] Update Grafana dashboards to visualize resource usage vs. limits

## Summary

Closed DEBT-04. Applied CPU/memory requests and limits to all 7 Helm-managed services (monitoring, keycloak, vault, ingress-nginx, cert-manager, external-secrets, seaweedfs) and the plain-manifest PostgreSQL StatefulSet. Sizing based on live `kubectl top` data — requests at ~80% of observed, limits at 2–3x requests. Added custom Grafana dashboard (`homelab-resources-dashboard` ConfigMap) scoped to all homelab namespaces with bar gauges (% of limit), detail tables, and time-series trends for memory and CPU.

## Bugs / Unplanned Work

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

## Tech Debt

None incurred.
