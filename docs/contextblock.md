Context Block
Date: 2026-02-28
Phase: Phase 1 complete. Day 1 done.
State: Cluster running. ArgoCD installed and syncing from GitHub. All Phase 1 apps healthy:
       cert-manager, cert-manager-issuers, ingress-nginx, seaweedfs all Synced/Healthy.
       ingress-nginx LoadBalancer pending until `minikube tunnel` is active (expected).
Blockers: None.
Next: Phase 2 — Monitoring (Prometheus + Grafana).

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB, Tahoe 26.3, minikube qemu2 driver.
Repo: GitHub private (https://github.com/lustoerk/k8ts.git), migrating to self-hosted GitLab in Phase 5.

Stack in scope (Phase 1):
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS

Deferred:
Monitoring (Phase 2), SOPS (Phase 3), Vault+ESO (Phase 4),
GitLab (Phase 5), Runner (Phase 6), Keycloak (Phase 7)
