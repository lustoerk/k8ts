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

**BUG-02: camunda/keycloak image incompatible with keycloakx chart**
- Symptom: main container crashes immediately; log: `/opt/bitnami/scripts/keycloak/entrypoint.sh: line 35: exec: start: not found`
- Cause: `camunda/keycloak:25` is Bitnami-based; the Bitnami entrypoint tries to `exec start` as a binary (not found), whereas the keycloakx chart is designed for the official Keycloak image which accepts `start` as a CLI subcommand
- Fix: Changed image to `quay.io/keycloak/keycloak:26.5.3` (the chart's appVersion default)

**BUG-03: Keycloak 26 production mode requires KC_HOSTNAME**
- Symptom: `ERROR: hostname is not configured; either configure hostname, or set hostname-strict to false`
- Cause: Keycloak 26 enforces hostname configuration in production mode; no hostname was set
- Fix: Added `KC_HOSTNAME=keycloak.homelab` and `KC_HOSTNAME_STRICT=false` to `extraEnv`

### Tech Debt

