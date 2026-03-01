# Phase 4 — Keycloak

**Date:** 2026-03-01

### Tasks

- [x] Deploy Keycloak (Helm, standalone, ingress + TLS at `keycloak.homelab`)
- [x] Bootstrap Keycloak realm and admin credentials (stored in Vault)
- [x] Configure Grafana OAuth via Keycloak
- [x] Configure ArgoCD SSO via Keycloak

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

**BUG-04: Grafana OAuth redirect_uri rejected by Keycloak**
- Symptom: Keycloak error page "Invalid parameter: redirect_uri"
- Cause: `root_url` not set in Grafana; pod derives callback scheme from internal request (`http://`), which doesn't match the `https://graf.homelab/*` URI registered in the Keycloak client
- Fix: Added `server.root_url: https://graf.homelab` to `grafana.ini`

**BUG-05: Grafana login denied — missing PKCE code_challenge**
- Symptom: Grafana log `error=invalid_request errorDesc="Missing parameter: code_challenge_method"`
- Cause: Keycloak client has `pkce.code.challenge.method: S256` enforced in the realm JSON, but Grafana wasn't sending the PKCE challenge
- Fix: Added `use_pkce: true` to `auth.generic_oauth` in `grafana.ini`

**BUG-06: Grafana OAuth token exchange fails — keycloak.homelab not resolvable in-cluster**
- Symptom: Grafana log `dial tcp: lookup keycloak.homelab on 10.96.0.10:53: server misbehaving`
- Cause: `keycloak.homelab` only exists in the host `/etc/hosts`; CoreDNS has no record of it, so pod→pod backchannel calls (token exchange, userinfo) fail
- Fix: Changed `token_url` and `api_url` to use `http://keycloak-keycloakx-http.keycloak.svc.cluster.local:80/...`; `auth_url` remains the public hostname (browser-facing)

**BUG-07: ArgoCD OIDC fails — keycloak.homelab not resolvable in-cluster**
- Symptom: ArgoCD log `failed to query provider: oidc: issuer did not match... expected "https://..." got "http://..."`
- Cause: `keycloak.homelab` not in CoreDNS; ArgoCD server pod could not reach the OIDC discovery endpoint. Fixed DNS, but the discovery doc still returned `http://` issuer because Keycloak wasn't reading `X-Forwarded-Proto` from nginx
- Fix: Patched CoreDNS `kube-system/coredns` ConfigMap to add `10.107.140.105 keycloak.homelab` in the `hosts` block; added homelab CA cert as `rootCA` in `argocd-cm.yaml` `oidc.config`

**BUG-08: Keycloak issuer returns http:// despite HTTPS ingress**
- Symptom: Discovery doc `issuer` field returns `http://keycloak.homelab/...` even when accessed via `https://`
- Cause (attempt 1): `KC_PROXY_HEADERS=xforwarded` in `extraEnv` was silently overridden by the chart's hardcoded `KC_PROXY_HEADERS=forwarded` — first env var occurrence wins in containerd
- Cause (attempt 2): `KC_HOSTNAME_URL` is deprecated Keycloak v1 hostname SPI syntax; ignored in KC 26 hostname v2 with a warning
- Fix: `KC_HOSTNAME=https://keycloak.homelab` — in Keycloak 24+ hostname v2, `KC_HOSTNAME` accepts a full URL including scheme, explicitly pinning the issuer to `https://`

### Tech Debt

None incurred this phase.
