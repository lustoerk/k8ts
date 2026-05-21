# ADR 008 — Monitoring Stack

## Context

Phase 2 adds observability. Need metrics collection, dashboards, and alerting
infrastructure that mirrors a production CNCF monitoring stack.

## Decision

kube-prometheus-stack (Helm chart) deploying Prometheus, Grafana, and
Alertmanager. Node exporter and kube-state-metrics included for cluster-level
metrics. Alertmanager deployed but no receivers configured — present for
architectural completeness, not active alerting.

Components enabled: Prometheus, Grafana, Alertmanager, node-exporter,
kube-state-metrics.

Storage: minikube hostPath (standard StorageClass) for Prometheus TSDB and
Grafana data. SeaweedFS is object storage, not block storage — not appropriate
for TSDB workloads.

Retention: 15 days (Prometheus default). Sufficient for homelab PoC work.

## Tradeoffs Accepted

Alertmanager runs with no receivers configured. Firing alerts have nowhere to
go. Acceptable — the goal is to validate the stack topology, not operate alerts.
An alerting destination (Slack webhook or similar) is deferred until Vault is
stable, so receiver credentials can be stored in Vault rather than plaintext values.

hostPath storage is not durable across minikube delete. Metrics history is
ephemeral. Acceptable for a lab that rebuilds periodically.

No resource requests or limits are set. Risk of OOM increases as more workloads
are added. Resource tuning is deferred to DEBT-04 before Phase 4.

## Status

**No change required.** Current implementation matches decision.
