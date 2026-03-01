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

- [x] Scaffold `infra/monitoring` directory
- [x] Add `apps/monitoring.yaml` ArgoCD Application (kube-prometheus-stack)
- [x] Configure `values.yaml` for arm64 compatibility
- [ ] Verify Prometheus/Grafana ingress and TLS

### Bugs / Unplanned Work

- **BUG-01** — `bootstrap.sh`: `--label` flag invalid on `kubectl create secret generic`
  - Symptom: Printed instructions used `--label` which is not a valid flag; running the command as shown would silently drop the label, causing ArgoCD to ignore the secret.
  - Fix: Split into two commands — `kubectl create secret generic` (without label) followed by `kubectl label secret`.

- **BUG-02** — `bootstrap.sh`: `read` prompt exits script under `set -euo pipefail` in non-interactive shells
  - Symptom: `read` returns non-zero when stdin is not a terminal, causing the script to exit before `kubectl apply root-app.yaml`, leaving root-app unapplied.
  - Fix: Changed to `read -r -p "..." || true` so non-interactive shells continue past the prompt.

- **BUG-03** — `bootstrap.sh` cannot be run from a subprocess (Claude Code, CI) due to socket_vmnet fd passing restrictions
  - Symptom: `minikube start` fails with `Unable to query local socket address: Operation not supported on socket` when invoked from a child process.
  - Fix: Script is correct. Constraint: `bootstrap.sh` must be run from a direct terminal session on macOS with qemu2+socket_vmnet.

- **BUG-04** — socket_vmnet enters broken state after `minikube delete`, blocking subsequent `minikube start`
  - Symptom: `Unable to query local socket address` or `Connection refused` on `/opt/homebrew/var/run/socket_vmnet` after cluster teardown.
  - Fix: `sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.socket_vmnet.plist && sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.socket_vmnet.plist`

### Tech Debt

None.