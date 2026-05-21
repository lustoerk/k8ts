# Phase 0 — Prerequisites & Scaffold

**Date:** 2026-02-28

### Tasks

- [x] Install core tools: minikube 1.38.1, helm 4.1.1, kubectl 1.35.2, qemu 10.2.1, socket_vmnet 1.2.2
- [x] Configure socket_vmnet as launchd root service
- [x] Smoke test qemu2 driver (`minikube start --driver=qemu2` → node Ready → `minikube delete`)
- [x] Create repo on GitHub (private, `lustoerk/k8ts`)
- [x] Scaffold directory structure: `apps/`, `infra/`, `bootstrap/`, `docs/`
- [x] Write ArgoCD Application manifests for all Phase 1 services
- [x] Write Helm values files for cert-manager, ingress-nginx, seaweedfs
- [x] Write ADRs 01–07
- [x] Write `bootstrap/bootstrap.sh` and `bootstrap/root-app.yaml`
- [x] Write `CLAUDE.md` operational context

### Bugs / Unplanned Work

None.

### Tech Debt

- `bootstrap/bootstrap.sh` prompts for manual secret creation mid-run (read -p). Acceptable for Day 0; automate in Phase 3 when SOPS is in place.
