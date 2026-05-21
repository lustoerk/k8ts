# Phase 2 — Monitoring (Prometheus + Grafana)

**Date:** 2026-03-01

### Tasks

- [x] Scaffold `infra/monitoring` directory
- [x] Add `apps/monitoring.yaml` ArgoCD Application (kube-prometheus-stack)
- [x] Configure `values.yaml` for arm64 compatibility
- [x] Verify Prometheus/Grafana ingress and TLS

### Bugs / Unplanned Work

- **BUG-03** — `bootstrap.sh` cannot be run from a subprocess (Claude Code, CI) due to socket_vmnet fd passing restrictions
  - Symptom: `minikube start` fails with `Unable to query local socket address: Operation not supported on socket` when invoked from a child process.
  - Fix: Script is correct. Constraint: `bootstrap.sh` must be run from a direct terminal session on macOS with qemu2+socket_vmnet.

- **BUG-04** — socket_vmnet enters broken state after `minikube delete`, blocking subsequent `minikube start`
  - Symptom: `Unable to query local socket address` or `Connection refused` on `/opt/homebrew/var/run/socket_vmnet` after cluster teardown.
  - Fix: `sudo launchctl unload /Library/LaunchDaemons/homebrew.mxcl.socket_vmnet.plist && sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.socket_vmnet.plist`

- **BUG-05** — ArgoCD root app did not auto-pick-up `apps/monitoring.yaml` immediately after push
  - Symptom: New monitoring Application not visible in ArgoCD UI despite file being in `apps/`.
  - Fix: Manually triggered Refresh on the root app in the ArgoCD UI. Default poll interval is ~3 minutes; root app refresh forces immediate re-read of `apps/`.

### Tech Debt

None.
