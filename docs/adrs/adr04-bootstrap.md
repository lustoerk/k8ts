# ADR 004 — Bootstrap Strategy (Revised)

## Context

Original bootstrap.sh had 6 imperative waves, post-install Jobs, API polling
loops, and a GitLab-to-ArgoCD handoff. Vast majority of that complexity existed
to bootstrap GitLab.

## Decision

Minimal imperative bootstrap: minikube start, install ArgoCD, apply root app.
Everything else is GitOps from the start.

## Rationale

With GitLab removed from bootstrap and secrets managed via Vault + ESO (ADR-009),
there are no chicken-egg dependencies left. ArgoCD can sync all remaining
components from GitHub without ordering hacks.

## Evolution

- **Day 0 (Phase 0):** Plain Kubernetes Secrets approach (no Vault dependency).
- **Phase 3:** Vault + ESO integration. Bootstrap now includes manual Vault unseal step after cluster restart (documented in README.md).
- **Secrets flow:** Vault → ESO → Kubernetes Secrets.

## Tradeoffs Accepted

- Bootstrap now requires Vault to be accessible (unsealed) before most components can sync.
- Manual unseal is a break-glass procedure; automated unseal deferred to Phase 8.

## Status

**Superseded by [ADR-009](adr09-vault.md)** — secrets now managed via Vault + ESO.
