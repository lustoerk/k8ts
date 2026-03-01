Context Block
Date: 2026-03-01
Phase: Phase 2 complete.
State: Cluster running. ArgoCD syncing from GitHub. All Phase 2 apps healthy:
       cert-manager, cert-manager-issuers, ingress-nginx, seaweedfs all Synced/Healthy.
       monitoring (kube-prometheus-stack) Synced/Healthy — Prometheus, Grafana, Alertmanager running.
       Grafana accessible at https://grafana.homelab.local (requires minikube tunnel + /etc/hosts entry).
       Alertmanager running with null receiver (no active alerting — architectural completeness only).
Blockers: None.
Next: Phase 3 — Vault + ESO.
History: Bootstrap fixed (BUG-01, BUG-02). Monitoring deployed (BUG-05).

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB, Tahoe 26.3, minikube qemu2 driver.
Repo: GitHub private (https://github.com/lustoerk/k8ts.git), migrating to self-hosted GitLab in Phase 5.

Stack in scope (Phase 2):
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS, kube-prometheus-stack

Deferred:
Keycloak (Phase 4), Learning phase (Phase 5), GitLab (Phase 6+)
SOPS: dropped — Vault+ESO covers secrets management end-to-end.
