# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)

---

## Phase 3 — Vault + ESO

**Date:** TBD

### Tasks

- [x] Deploy Vault (standalone, manual unseal, ingress + TLS)
- [x] Deploy External Secrets Operator
- [ ] Bootstrap Vault: init, unseal, KV engine, Kubernetes auth
- [ ] Wire ESO → Vault via ClusterSecretStore
- [ ] Migrate Grafana admin password out of plaintext values into Vault

### Bugs / Unplanned Work

None.

### Tech Debt

None.
