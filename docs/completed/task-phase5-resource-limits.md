# Task Plan: Phase 5 — Resource Limits & Requests

## Goal
Apply CPU/memory requests and limits to all Helm-managed workloads. Close DEBT-04.

## Current State (from `kubectl top`)

Node: 16 GiB total, ~6.9 GiB used (43%), ~222m CPU (5%).

| Pod | Actual Memory | Actual CPU |
|-----|---------------|------------|
| kube-apiserver | 1311 Mi | 14m |
| Prometheus | 989 Mi | 20m |
| Keycloak | 766 Mi | 2m |
| ArgoCD app-controller | 586 Mi | 8m |
| Grafana | 337 Mi | 2m |
| etcd | 322 Mi | 5m |
| Vault | 239 Mi | 6m |
| ArgoCD repo-server | 205 Mi | 11m |
| kube-controller-manager | 148 Mi | 3m |
| ingress-nginx | 128 Mi | 1m |
| ArgoCD dex-server | 110 Mi | 1m |
| Keycloak Postgres | 108 Mi | 1m |
| ESO (main) | 104 Mi | 1m |
| cert-manager cainjector | 91 Mi | 1m |
| ArgoCD applicationset | 78 Mi | 1m |
| SeaweedFS filer | 77 Mi | 1m |
| ArgoCD notifications | 76 Mi | 1m |
| SeaweedFS master | 59 Mi | 1m |
| cert-manager webhook | 55 Mi | 1m |
| vault-agent-injector | 50 Mi | 1m |
| ArgoCD redis | 46 Mi | 3m |
| Alertmanager | 45 Mi | 1m |
| Prometheus operator | 38 Mi | 1m |
| ESO cert-controller | 94 Mi | 1m |
| ESO webhook | 32 Mi | 1m |
| cert-manager | 29 Mi | 1m |
| node-exporter | 29 Mi | 1m |
| ArgoCD server | 61 Mi | 1m |
| SeaweedFS volume | 17 Mi | 1m |

## Approach

Set `requests` at ~80% of observed actual (headroom for variance), `limits` at 2–3x requests.
kube-system components (apiserver, etcd, scheduler, controller-manager) are not managed via our Helm values — skip.

### Strategy per service

**Sizing conventions used below:**
- `requests`: baseline for scheduling, set to observed usage with ~20% buffer
- `limits`: ceiling, set generously to avoid OOMKill under load (2x requests for memory-heavy, 4x CPU requests)

---

## Files to Change

### 1. `infra/monitoring/values.yaml` — kube-prometheus-stack
Covers: Prometheus, Grafana, Alertmanager, kube-state-metrics, node-exporter, operator.

Proposed additions:
```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        cpu: 100m
        memory: 1200Mi
      limits:
        cpu: 500m
        memory: 2000Mi

grafana:
  resources:
    requests:
      cpu: 50m
      memory: 400Mi
    limits:
      cpu: 200m
      memory: 600Mi

alertmanager:
  alertmanagerSpec:
    resources:
      requests:
        cpu: 10m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 128Mi

kube-state-metrics:
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 100m
      memory: 200Mi

prometheus-node-exporter:
  resources:
    requests:
      cpu: 10m
      memory: 40Mi
    limits:
      cpu: 100m
      memory: 80Mi

prometheusOperator:
  resources:
    requests:
      cpu: 10m
      memory: 50Mi
    limits:
      cpu: 100m
      memory: 128Mi
```

### 2. `infra/keycloak/values.yaml` — Keycloak + Postgres
```yaml
# Keycloak container
resources:
  requests:
    cpu: 100m
    memory: 900Mi
  limits:
    cpu: 1000m
    memory: 1500Mi

# PostgreSQL StatefulSet (keycloak-postgresql)
postgresql:
  primary:
    resources:
      requests:
        cpu: 50m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
```

### 3. `infra/vault/values.yaml` — Vault + agent injector
```yaml
server:
  resources:
    requests:
      cpu: 50m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

injector:
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
```

### 4. `infra/ingress-nginx/values.yaml`
```yaml
controller:
  resources:
    requests:
      cpu: 50m
      memory: 150Mi
    limits:
      cpu: 300m
      memory: 300Mi
```

### 5. `infra/cert-manager/values.yaml`
```yaml
resources:
  requests:
    cpu: 10m
    memory: 40Mi
  limits:
    cpu: 100m
    memory: 128Mi

webhook:
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi

cainjector:
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 100m
      memory: 200Mi
```

### 6. `infra/external-secrets/values.yaml`
```yaml
resources:
  requests:
    cpu: 10m
    memory: 128Mi
  limits:
    cpu: 100m
    memory: 256Mi

certController:
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 100m
      memory: 200Mi

webhook:
  resources:
    requests:
      cpu: 10m
      memory: 40Mi
    limits:
      cpu: 100m
      memory: 128Mi
```

### 7. `infra/seaweedfs/values.yaml`
```yaml
master:
  resources:
    requests:
      cpu: 10m
      memory: 80Mi
    limits:
      cpu: 200m
      memory: 256Mi

volume:
  resources:
    requests:
      cpu: 10m
      memory: 32Mi
    limits:
      cpu: 200m
      memory: 128Mi

filer:
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 200m
      memory: 256Mi
```

### 8. ArgoCD — no values.yaml; skip for now
ArgoCD is installed via Helm during bootstrap (not managed as a GitOps Application by itself). Resources can be revisited when ArgoCD is brought under GitOps management.

---

## Execution Order

1. Apply monitoring values → `helm template` → ArgoCD sync
2. Apply keycloak values → `helm template` → ArgoCD sync
3. Apply vault values → `helm template` → ArgoCD sync
4. Apply ingress-nginx, cert-manager, external-secrets, seaweedfs → `helm template` → ArgoCD sync
5. Run `kubectl top pods -A` post-sync to verify no OOMKills or throttling
6. Mark Phase 5 tasks done, update phase-log

---

## Risks

- **Keycloak + Prometheus** are the two heavy consumers (~750 Mi+ each). Memory limits set to 1.5–2x observed to avoid OOMKill on restart or load spikes.
- Keycloak Postgres sub-chart key path needs verification against chart version — will check during execution.
- ArgoCD is deliberately excluded (bootstrap-installed, not GitOps-managed).
