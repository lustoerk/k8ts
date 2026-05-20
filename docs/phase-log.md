# Phase Log

Forward-looking roadmap. Completed phases live in [`history/`](history/). Active session state lives in [`.scratch/LOG.md`](../.scratch/LOG.md).

## Completed

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)
- [Phase 3 — Vault + ESO](history/phase-3.md)
- [Phase 4 — Keycloak SSO](history/phase-4.md)
- [Phase 4 Review — Professionalization Roadmap](adrs/adr11-professionalization-roadmap.md)

---

## Phase 5 — Resource Limits & Requests `<-- current`

**Date:** TBD

Implement DEBT-04: production-grade resource management across all workloads.

### Tasks

- [x] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [/] Define and apply CPU/memory requests and limits for all Helm-managed services
- [ ] Validate cluster stability under constrained resources
- [x] Update Grafana dashboards to visualize resource usage vs. limits

### Bugs / Unplanned Work

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

### Tech Debt

---

## Phase 6 — Redis Operator

**Date:** TBD

Integrate the OT-CONTAINER-KIT Redis Operator as the first application-layer workload on the hardened platform.

### Tasks

- [ ] TBD

---

## Phase 7 — SeaweedFS Review & Integration

**Date:** TBD

Bring SeaweedFS from "deployed but unused" to a fully integrated, tested storage service.

### Tasks

- [ ] Enable S3 authentication (access key / secret key)
- [ ] Store S3 credentials in Vault, sync via ESO
- [ ] Enable SeaweedFS Prometheus metrics + add ServiceMonitor
- [ ] Build Grafana dashboard for SeaweedFS (capacity, request rate, latency)
- [ ] Expose SeaweedFS admin UI via ingress (`seaweedfs.homelab`)
- [ ] Evaluate Keycloak integration for admin UI access (OAuth2 proxy or native)
- [ ] Deploy a small test workload that reads/writes to the S3 endpoint
- [ ] Document S3 usage patterns for future workloads

---

## Phase 8 — Operational Hardening

**Date:** TBD

Close remaining tech debt and improve day-to-day operations.

### Tasks

- [ ] Declarative CoreDNS — replace manual `hosts` patching with GitOps-managed ConfigMap
- [ ] Vault auto-unseal or break-glass procedure
- [ ] Document "Bootstrap from Zero" disaster recovery runbook
- [ ] Persistent storage — mount macOS host folders into minikube for data survival across `minikube delete`
- [ ] `/etc/hosts` automation (script or LaunchAgent)

---

## Phase 9 — New Applications

**Date:** TBD

Only after the platform is hardened. Candidates:

- [ ] Forgejo or GitLab (self-hosted SCM + CI, Keycloak SSO)
- [ ] AI/ML workload using SeaweedFS S3 for model/data storage
- [ ] Additional Keycloak-integrated services as needed