Context Block
Date: 2026-02-28
Phase: Phase 1 scaffold committed. Day 0 not yet executed.
State: Repo has full scaffold (apps/, bootstrap/, infra/) and README day0 instructions.
       bootstrap.sh written. ArgoCD Applications defined. Helm values validated.
       No cluster running yet.
Blockers: None. Day 0 Mac setup (minikube qemu2 driver) is the next step.
Next: Execute Day 0 — install prerequisites, smoke-test qemu2 driver, then run bootstrap.sh.

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB, Tahoe 26.3, minikube qemu2 driver.
Repo: GitHub private (https://github.com/lustoerk/k8ts.git), migrating to self-hosted GitLab in Phase 5.

Stack in scope (Phase 1):
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS

Deferred:
Monitoring (Phase 2), SOPS (Phase 3), Vault+ESO (Phase 4),
GitLab (Phase 5), Runner (Phase 6), Keycloak (Phase 7)
