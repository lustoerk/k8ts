# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)
- [Phase 3 — Vault + ESO](history/phase-3.md)
- [Phase 4 — Keycloak](history/phase-4.md)
- [Phase 4 Review — Professionalization](adrs/adr11-professionalization-roadmap.md)

---

## Phase 5 — Resource Limits & Hardening

**Date:** 2026-03-01

### Tasks

- [ ] Implement DEBT-04: Resource requests/limits for all workloads (Prometheus, Keycloak, Vault, etc.)
- [ ] Fix CoreDNS GitOps (move from manual patch to declarative ConfigMap)
- [ ] Document "Bootstrap from Zero" disaster recovery procedure

---

## Phase 6 — GitLab (DEFERRED)

**Date:** TBD

### Tasks

- [ ] Deploy GitLab (self-hosted, ingress + TLS at `gitlab.homelab`)
- [ ] Migrate git remote from GitHub to GitLab
- [ ] Configure ArgoCD to sync from GitLab
- [ ] Configure Keycloak SSO for GitLab

### Bugs / Unplanned Work

**BUG-09** ArgoCD OIDC `invalid_scope: Invalid scopes: openid profile email groups`
- **Symptom:** ArgoCD OIDC login rejected by Keycloak with `invalid_scope` on the `groups` scope.
- **Fix:** Removed `groups` from `requestedScopes` in `argocd-cm`. `groups` is a Keycloak protocol mapper (JWT claim), not a registered OAuth scope. The claim is still injected into the ID token via `oidc-group-membership-mapper` on the `argocd` client, and RBAC continues to work via `scopes: '[groups]'` in `argocd-rbac-cm`.

### Tech Debt

