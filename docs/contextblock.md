Context Block
Date: 2026-03-01
Phase: Phase 3 complete.
State: Cluster running. ArgoCD syncing from GitHub. All Phase 3 apps healthy:
       cert-manager, cert-manager-issuers, ingress-nginx, seaweedfs all Synced/Healthy.
       monitoring (kube-prometheus-stack) Synced/Healthy — Prometheus, Grafana, Alertmanager running.
       vault (standalone, unsealed) Synced/Healthy — UI at vault.homelab.
       external-secrets Synced/Healthy — ClusterSecretStore vault-backend Ready.
       vault-config Synced/Healthy — ExternalSecret grafana-admin Ready, secret synced.
       Grafana admin credentials served from Vault via ESO. No plaintext secrets in git.
       Services accessible via ingress: argo.homelab, prom.homelab, graf.homelab,
       alman.homelab, s3.homelab, vault.homelab (requires minikube tunnel + /etc/hosts ClusterIP entry).
Blockers: None.
Next: Phase 4 — Keycloak.
History: Bootstrap fixed (BUG-01, BUG-02). Monitoring deployed (BUG-05). Vault+ESO wired (BUG-01 Phase 3).

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB, Tahoe 26.3, minikube qemu2 driver.
Repo: GitHub private (https://github.com/lustoerk/k8ts.git), migrating to self-hosted GitLab in Phase 5.

Stack in scope (Phase 3):
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS, kube-prometheus-stack, Vault, ESO

Deferred:
Keycloak (Phase 4), GitLab (Phase 5), GitLab Runner (Phase 6+).
SOPS: dropped — Vault+ESO covers secrets management end-to-end.
Open debt: DEBT-03 (/etc/hosts automation), DEBT-04 (resource requests/limits).
