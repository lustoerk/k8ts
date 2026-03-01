ADR 008 — Monitoring Stack
Context
Phase 2 adds observability. Need metrics collection, dashboards, and alerting
infrastructure that mirrors a production CNCF monitoring stack.
Decision
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
Tradeoffs Accepted
Alertmanager runs with no receivers configured. Firing alerts have nowhere to
go. Acceptable — the goal is to validate the stack topology, not operate alerts.
hostPath storage is not durable across minikube delete. Metrics history is
ephemeral. Acceptable for a lab that rebuilds periodically.