Context Block
Date: 2026-03-01
Phase: Phase 5 complete.
State: Cluster running. All Helm-managed services have CPU/memory requests and limits.
       No OOMKills observed post-rollout. Vault unsealed and healthy.
       Custom Grafana dashboard "Homelab — Resource Usage vs Limits" deployed.
Blockers: None.
Next: Phase 6 — SeaweedFS Review & Integration.
History: Phase 5 complete. DEBT-04 closed. 4 bugs logged (SeaweedFS string format,
         vault anti-affinity deadlocks, OnDelete strategy, root app propagation).

Hardware: MacBook Pro Nov 2024, Apple M4 Max, 128GB.
Repo: GitHub private, GitLab migration deferred.

Stack: minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS, Prometheus/Grafana, Vault, Keycloak.

Open debt: CoreDNS (Declarative), Vault (Auto-unseal/Break-glass), hostPath persistence.
