Context Block
Date: 2026-03-01
Phase: Phase 4 complete.
State: Cluster running. ArgoCD syncing from GitHub. All Phase 4 apps healthy:
       cert-manager, cert-manager-issuers, ingress-nginx, seaweedfs all Synced/Healthy.
       monitoring (kube-prometheus-stack) Synced/Healthy — Prometheus, Grafana, Alertmanager running.
       vault (standalone, unsealed) Synced/Healthy — UI at vault.homelab.
       external-secrets Synced/Healthy — ClusterSecretStore vault-backend Ready.
       keycloak Synced/Healthy — Keycloak 26.5.3 at keycloak.homelab, realm homelab imported.
       keycloak-config Synced/Healthy — ESO ExternalSecrets for argocd + grafana client secrets.
       Grafana OAuth via Keycloak working (graf.homelab).
       ArgoCD OIDC via Keycloak working (argo.homelab).
       CoreDNS patched: keycloak.homelab resolves to ingress ClusterIP in-cluster.
Blockers: None.
Next: Phase 5 — GitLab.
History: Bootstrap fixed (BUG-01, BUG-02). Monitoring deployed. Vault+ESO wired. Keycloak SSO (8 bugs).

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB, Tahoe 26.3, minikube qemu2 driver.
Repo: GitHub private (https://github.com/lustoerk/k8ts.git), migrating to self-hosted GitLab in Phase 5.

Stack in scope (Phase 4):
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS, kube-prometheus-stack, Vault, ESO, Keycloak

Deferred:
GitLab (Phase 5), GitLab Runner (Phase 6+).
SOPS: dropped — Vault+ESO covers secrets management end-to-end.
Open debt: DEBT-03 (/etc/hosts automation), DEBT-04 (resource requests/limits).
Note: CoreDNS hosts entry for keycloak.homelab is imperative — must be re-applied after minikube delete.
