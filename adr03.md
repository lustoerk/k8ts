ADR 003 — Secrets Management (Revised)
Context
Original design used Vault + ESO for all secrets. This created init/unseal
ordering issues and a complex bootstrap dependency chain.
Decision
Plain Kubernetes Secrets for all components initially.
Rationale
The minimal stack has very few secrets (SeaweedFS S3 credentials, ArgoCD admin).
The complexity of Vault + ESO is not justified until there are enough consumers
to warrant centralized secrets management.
Tradeoffs Accepted

Secrets stored as base64 in etcd, not encrypted at rest (minikube default).
Secrets may end up committed to Git if not careful. Mitigation: use
SealedSecrets or SOPS in the growth path before Vault.
Not production-like. Accepted — Vault migration is a planned learning phase.