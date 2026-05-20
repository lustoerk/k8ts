# Phase 5 — Resource Limits & Requests

**Initial close:** 2026-03-01 (premature, see below)
**Reopened:** 2026-05-20
**Final close:** 2026-05-20

## Tasks

- [x] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [x] Define and apply CPU/memory requests and limits for all Helm-managed services
- [x] Update Grafana dashboards to visualize resource usage vs. limits
- [x] Validate cluster stability under constrained resources

## Summary

Phase 5 was initially closed on 2026-03-01 with all four boxes checked, but a re-audit on 2026-05-20 found **11 containers still missing `resources`**:

- The 7 ArgoCD components, because ArgoCD is bootstrap-installed via `bootstrap.sh` with `--set` flags only — the previous pass touched ArgoCD-managed services but missed ArgoCD itself.
- 4 kube-prometheus-stack sidecars (Prometheus + Alertmanager `config-reloader`, Grafana `sc-dashboard` + `sc-datasources`), because the previous pass set resources only on the primary containers and used the wrong chart key.

### Recovery work (2026-05-20)

- Added `infra/argocd/values.yaml` as the managed source for the argo-cd chart, switched `bootstrap.sh` to use it via `-f`, sized all 7 components from observed usage.
- Added `prometheusOperator.prometheusConfigReloader.resources` (operator-wide CLI flag, covers both Prometheus + Alertmanager config-reloaders) and `grafana.sidecar.resources` to `infra/monitoring/values.yaml`.
- Resolved a downstream helm-upgrade conflict on `argocd-cm` / `argocd-rbac-cm` (see BUG-10/11 below) by disabling chart-side creation of those ConfigMaps and adopting them as raw-manifest-only via the `argocd-ingress` Application.

### Validation (2026-05-20)

- **Gap audit:** 0 application containers without `resources`. The 7 remaining (etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kube-proxy, metrics-server, storage-provisioner) are kube-system infrastructure managed by minikube/kubeadm — out of scope.
- **OOM check:** cluster-wide audit found 0 `OOMKilled` `lastState.terminated.reason` across all namespaces.
- **CFS throttling proof:** drove a `while :; do :; done` busy loop in `argocd-server` (100m CPU limit). Pod's cgroup `cpu.stat` reported `nr_throttled=1396` of `nr_periods=2660` (52.5% throttle rate, 92s cumulative throttled time). Pod stayed `Running`, 0 restarts.

### Initial-close work (2026-03-01)

Applied CPU/memory requests and limits to the 7 Helm-managed services touched by the original Phase 5 pass (monitoring, keycloak, vault, ingress-nginx, cert-manager, external-secrets, seaweedfs) and the plain-manifest PostgreSQL StatefulSet. Sizing convention: requests at ~80% of observed, limits at 2–3× requests. Added the custom Grafana dashboard `homelab-resources-dashboard` ConfigMap with bar gauges (% of limit), detail tables, and time-series for memory and CPU.

## Bugs / Unplanned Work

### Initial close (2026-03-01)

**BUG-01–BUG-04** recorded in prior phase-log archives.

### Re-open (2026-05-20)

**GAP-01** ArgoCD itself had no `resources` set on any of its 7 components
- **Symptom:** Live `kubectl get pods -A -o json | jq` audit found `application-controller`, `applicationset-controller`, `dex-server`, `notifications-controller`, `redis`, `repo-server`, `server` all running with `resources: {}`.
- **Root cause:** `bootstrap.sh` installed ArgoCD via inline `--set` flags only, with no values file. The previous Phase 5 pass touched the 7 ArgoCD-managed services but missed ArgoCD itself, which is bootstrap-installed.
- **Fix:** Added `infra/argocd/values.yaml` (managed source of truth); switched `bootstrap.sh` to `helm upgrade --install ... -f infra/argocd/values.yaml`. Same NodePort + `server.insecure` settings preserved.

**GAP-02** kube-prometheus-stack config-reloader and Grafana sidecars had no resources
- **Symptom:** 4 containers — `config-reloader` on Prometheus and Alertmanager, plus `grafana-sc-dashboard` and `grafana-sc-datasources` — running with empty `resources`.
- **Root cause:** Previous pass set resources only on the primary containers, not the sidecars. The config-reloader knob is at `prometheusOperator.prometheusConfigReloader.resources` (operator-level, applied to all CRs via CLI flags), not under each `*Spec`.
- **Fix:** Added `prometheusOperator.prometheusConfigReloader.resources` and `grafana.sidecar.resources` to `infra/monitoring/values.yaml`.

**BUG-10** `helm upgrade argocd` rejected on `argocd-cm` / `argocd-rbac-cm` field-manager conflict
- **Symptom:** `UPGRADE FAILED: conflict occurred while applying object argocd/argocd-cm: conflicts with "argocd-controller" using v1: .data.timeout.reconciliation, .data.url` (and similar for `argocd-rbac-cm`).
- **Root cause:** Both the chart and the `argocd-ingress` Application apply these ConfigMaps. Server-side apply detects two managers with conflicting field values.
- **Fix:** Set `configs.cm.create: false` and `configs.rbac.create: false` in `infra/argocd/values.yaml` so the chart skips them. Sole manager is now the `argocd-ingress` Application. Also added `directory.include: "{argocd-cm.yaml,argocd-rbac-cm.yaml,ingress.yaml}"` to `apps/argocd-ingress.yaml` so ArgoCD does not attempt to apply the new `values.yaml` as a K8s manifest.

**BUG-11** Helm upgrade with `cm.create: false` deleted the live ConfigMap; reapplied manifest invisible to controllers
- **Symptom:** After helm upgrade, ArgoCD `server` and `application-controller` CrashLoopBackOff with `fatal: configmap "argocd-cm" not found`. Reapplying `infra/argocd/argocd-cm.yaml` via `kubectl apply` did not unstick them.
- **Root cause:** Helm interpreted the change from `cm.create: true` → `false` as a removal and deleted the existing argocd-cm. The reapplied raw manifest had no labels; ArgoCD's configmap informer filters by `app.kubernetes.io/part-of=argocd`.
- **Fix:** Added `app.kubernetes.io/name` + `app.kubernetes.io/part-of: argocd` labels to `infra/argocd/argocd-cm.yaml` and `argocd-rbac-cm.yaml`. After reapply, controllers picked them up immediately on next pod restart.

**BUG-12** Grafana dashboard `homelab-resources` "usage" panels return No Data
- **Symptom:** "CPU Usage % of Limit — by Namespace" and similar panels show "No data". Limits/requests panels work.
- **Root cause:** Dashboard queries filter `container_*` cAdvisor metrics with `container!=""`, but in this minikube/kube-prometheus-stack setup cAdvisor only emits pod-level cgroup series with no `container` label — so the filter matches zero series. Limits/requests panels work because they use `kube_pod_container_resource_*` from kube-state-metrics, which has the label. Resource enforcement itself is verified live via `kubectl top` + cgroup `cpu.stat`; this is a dashboard-only issue.
- **Fix:** Not yet — investigate whether kubelet/cAdvisor can be made to expose per-container series, or rework the dashboard queries to drop the `container!=""` filter and aggregate at pod level.

## Tech Debt

None incurred.
