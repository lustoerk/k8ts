# ADR 002 — Git Remote (Revised)

## Context

Original design used self-hosted GitLab as ArgoCD's Git source. This created
the largest chicken-egg problem: ArgoCD needs a repo before GitLab exists,
and GitLab is the heaviest component to bootstrap.

## Decision

GitHub (private repo) as ArgoCD's Git remote.

## Rationale

Eliminates GitLab from the bootstrap critical path. ArgoCD works from minute
one. GitLab becomes a future phase component deployed via GitOps like any other
app.

## Tradeoffs Accepted

- External dependency on GitHub. Not air-gapped.
- Not the self-hosted pattern used at work. Reclaimed when GitLab is added.
- Requires a GitHub PAT or deploy key for ArgoCD repo access.
