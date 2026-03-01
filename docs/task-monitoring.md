# Task Plan — Phase 2: Monitoring (Prometheus + Grafana)

## Scope

Deploy kube-prometheus-stack via ArgoCD. Prometheus, Grafana, Alertmanager,
node-exporter, and kube-state-metrics. Accessible via ingress with TLS.

## Files to Create

- `infra/monitoring/values.yaml` — Helm values for kube-prometheus-stack
- `apps/monitoring.yaml` — ArgoCD Application manifest

## Steps

### 1. Add Helm repo (local, for validation only)
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. Create `apps/monitoring.yaml`
- Source: prometheus-community/kube-prometheus-stack
- Values from: `$values/infra/monitoring/values.yaml`
- Destination namespace: `monitoring`
- Sync wave: `"2"` (alongside seaweedfs — no dependency on it)
- syncPolicy: automated, prune, selfHeal, CreateNamespace=true

### 3. Create `infra/monitoring/values.yaml`
Propose structure, wait for approval before writing. Key sections:
- `prometheus.prometheusSpec`: retention, storage (hostPath via storageClass)
- `grafana`: adminPassword, ingress (host, TLS, cert-manager annotation)
- `alertmanager`: enabled, no receivers
- `nodeSelector` / `tolerations`: arm64 overrides if needed (validate against chart)

### 4. Validate
```
helm template monitoring prometheus-community/kube-prometheus-stack \
  -f infra/monitoring/values.yaml
```
Confirm renders without error. Note any arm64 image warnings.

### 5. Sync and verify
- ArgoCD syncs `monitoring` namespace
- Confirm Prometheus, Grafana, Alertmanager pods Running
- Confirm Grafana ingress resolves with valid TLS cert
- Confirm Prometheus scraping cluster targets (`/targets`)

## Risks

- **arm64 image availability**: some sub-charts (e.g. windows exporters) default
  to amd64-only images. May need to disable or override `nodeSelector`.
- **CRD install**: kube-prometheus-stack installs CRDs (PrometheusRule,
  ServiceMonitor, etc.). These are bundled in the chart, not a separate
  Application — acceptable since we control the upgrade cadence.
- **Grafana admin password**: plain value in values.yaml for now (ADR03 —
  plain secrets until Phase 3 SOPS).

## Done When

All Phase 2 tasks checked off in `docs/phase-log.md` and all apps
Synced/Healthy in ArgoCD.