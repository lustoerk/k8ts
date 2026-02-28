# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)

---

## Phase 2 — Monitoring (Prometheus + Grafana)

**Date:** 2026-02-28

### Tasks

- [ ] Scaffold `infra/monitoring` directory
- [ ] Add `apps/monitoring.yaml` ArgoCD Application (kube-prometheus-stack)
- [ ] Configure `values.yaml` for arm64 compatibility
- [ ] Verify Prometheus/Grafana ingress and TLS

### Bugs / Unplanned Work

- **BUG-01** — `bootstrap.sh`: `--label` flag invalid on `kubectl create secret generic`
  - Symptom: Printed instructions used `--label` which is not a valid flag; running the command as shown would silently drop the label, causing ArgoCD to ignore the secret.
  - Fix: Split into two commands — `kubectl create secret generic` (without label) followed by `kubectl label secret`.

- **BUG-02** — `bootstrap.sh`: `read` prompt exits script under `set -euo pipefail` in non-interactive shells
  - Symptom: `read` returns non-zero when stdin is not a terminal, causing the script to exit before `kubectl apply root-app.yaml`, leaving root-app unapplied.
  - Fix: Changed to `read -r -p "..." || true` so non-interactive shells continue past the prompt.

### Tech Debt

None.