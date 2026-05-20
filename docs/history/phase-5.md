# Phase 5 — Resource Limits & Requests

**Initial close:** 2026-03-01 (premature, see below)
**Reopened:** 2026-05-20
**Final close:** TBD (validation pending)

## Tasks

- [x] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [x] Define and apply CPU/memory requests and limits for all Helm-managed services
- [x] Update Grafana dashboards to visualize resource usage vs. limits
- [ ] Validate cluster stability under constrained resources (in progress)

## Summary

Phase 5 was initially closed on 2026-03-01 with all four boxes checked, but a re-audit on 2026-05-20 found **11 containers still missing `resources`**:

- The 7 ArgoCD components, because ArgoCD is bootstrap-installed via `bootstrap.sh` with `--set` flags only — the previous pass touched ArgoCD-managed services but missed ArgoCD itself.
- 4 kube-prometheus-stack sidecars (Prometheus + Alertmanager `config-reloader`, Grafana `sc-dashboard` + `sc-datasources`), because the previous pass set resources only on the primary containers and used the wrong chart key.

### Recovery work (2026-05-20)

- Added `infra/argocd/values.yaml` as the managed source for the argo-cd chart, switched `bootstrap.sh` to use it via `-f`, sized all 7 components from observed usage.
- Added `prometheusOperator.prometheusConfigReloader.resources` (operator-wide CLI flag, covers both Prometheus + Alertmanager config-reloaders) and `grafana.sidecar.resources` to `infra/monitoring/values.yaml`.
- Resolved a downstream helm-upgrade conflict on `argocd-cm` / `argocd-rbac-cm` (see BUG-10/11 in `docs/phase-log.md`) by disabling chart-side creation of those ConfigMaps and adopting them as raw-manifest-only via the `argocd-ingress` Application.

### Initial-close work (2026-03-01)

Applied CPU/memory requests and limits to the 7 Helm-managed services touched by the original Phase 5 pass (monitoring, keycloak, vault, ingress-nginx, cert-manager, external-secrets, seaweedfs) and the plain-manifest PostgreSQL StatefulSet. Sizing convention: requests at ~80% of observed, limits at 2–3× requests. Added the custom Grafana dashboard `homelab-resources-dashboard` ConfigMap with bar gauges (% of limit), detail tables, and time-series for memory and CPU.

## Bugs / Unplanned Work

Initial-close bugs (BUG-01 through BUG-04) and re-open work (GAP-01/02, BUG-10/11) are recorded in `docs/phase-log.md` under the active phase block. They will be archived here when the phase is finally closed.

## Tech Debt

None incurred.
