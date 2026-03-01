ADR 004 — Bootstrap Strategy (Revised)
Context
Original bootstrap.sh had 6 imperative waves, post-install Jobs, API polling
loops, and a GitLab-to-ArgoCD handoff. Vast majority of that complexity existed
to bootstrap GitLab.
Decision
Minimal imperative bootstrap: minikube start, install ArgoCD, apply root app.
Everything else is GitOps from the start.
Rationale
With GitLab removed from bootstrap and secrets managed as plain k8s Secrets,
there are no chicken-egg dependencies left. ArgoCD can sync all remaining
components from GitHub without ordering hacks.