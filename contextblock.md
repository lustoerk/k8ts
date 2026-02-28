Context Block
Date: 2025-02-28
Phase: Design v2 — minimal stack scoped to SeaweedFS experimentation.
Next: Review → Build (bootstrap.sh + platform repo)
Goal
Local Kubernetes homelab. Primary target: working SeaweedFS experimentation
(CSI + S3 API). Secondary: GitOps foundation that grows incrementally.
Hardware
MacBook M4 128GB.
Stack in Scope (Minimal)
minikube, ArgoCD, cert-manager, ingress-nginx, SeaweedFS
Deferred to Future Phases
Vault, ESO, GitLab, GitLab Runner, Keycloak, Monitoring (kube-prometheus-stack)