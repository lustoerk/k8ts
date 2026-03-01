# Phase Log

Running record of work done per phase. Includes planned tasks, bugs encountered, and tech debt incurred.

---

## History

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)
- [Phase 3 — Vault + ESO](history/phase-3.md)

---

## Phase 4 — Keycloak

**Date:** TBD

### Tasks

- [ ] Deploy Keycloak (Helm, standalone, ingress + TLS at `keycloak.homelab`)
- [ ] Bootstrap Keycloak realm and admin credentials (stored in Vault)
- [ ] Configure Grafana OAuth via Keycloak
- [ ] Configure ArgoCD SSO via Keycloak

### Bugs / Unplanned Work

**BUG-01: realm-import-prep init container crashes with "Invalid back reference"**
- Symptom: `keycloak-keycloakx-0` stuck in `Init:CrashLoopBackOff`; init container log: `sed: bad regex '...': Invalid back reference`
- Cause: `sed` replacement string receives secret value containing `\2` (and similar `\N` sequences), which sed interprets as a regex backreference
- Fix: Replaced `sed` with `envsubst` (Alpine `gettext`); updated realm ConfigMap placeholders from `$(VAR)` to `${VAR}` syntax

### Tech Debt

