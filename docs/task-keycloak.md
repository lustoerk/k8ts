# Task Plan: Phase 4 — Keycloak

## Goal

Deploy Keycloak as the homelab SSO provider, wire it to Vault for credential storage,
and configure Grafana and ArgoCD to authenticate via Keycloak OIDC.

---

## Waves

Keycloak will be wave 5 (after vault wave 3, vault-config wave 4).
A `keycloak-config` app (raw manifests — ExternalSecrets) will be wave 6.

---

## Step-by-Step Plan

### Step 1: Helm chart research

Chart: `codecentric/keycloakx` or `bitnami/keycloak`.
- Bitnami is the more maintained option for 2025+; upstream Keycloak operator is heavy.
- Use `bitnami/keycloak` chart. Standalone (1 replica), PostgreSQL dependency disabled
  (use embedded H2 for homelab — acceptable for single-tenant, no-HA requirement).
- Actually: Bitnami keycloak chart requires PostgreSQL (H2 removed upstream in KC 20+).
  Use the bundled PostgreSQL sub-chart (`postgresql.enabled: true`).

**Decision:** `bitnami/keycloak`, latest stable (~24.x chart / KC 26.x app).

### Step 2: Vault secrets

Store in Vault at path `keycloak`:
- `admin-user`: `admin`
- `admin-password`: (generated, strong)

ExternalSecret in `infra/keycloak-config/` syncs to namespace `keycloak`,
secret name `keycloak-admin`, keys `admin-user` and `admin-password`.

### Step 3: New files

```
apps/keycloak.yaml                          # ArgoCD Application, wave 5
apps/keycloak-config.yaml                   # ArgoCD Application, wave 6
infra/keycloak/values.yaml                  # Helm values
infra/keycloak-config/keycloak-external-secret.yaml
```

### Step 4: Grafana OIDC

Keycloak realm: `homelab`
Grafana client: `grafana` (confidential, redirect URI: `https://graf.homelab/login/generic_oauth`)

Grafana values additions (in `infra/monitoring/values.yaml`):
```yaml
grafana:
  grafana.ini:
    auth.generic_oauth:
      enabled: true
      name: Keycloak
      allow_sign_up: true
      client_id: grafana
      client_secret: $__env{GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET}
      scopes: openid email profile
      auth_url: https://keycloak.homelab/realms/homelab/protocol/openid-connect/auth
      token_url: https://keycloak.homelab/realms/homelab/protocol/openid-connect/token
      api_url: https://keycloak.homelab/realms/homelab/protocol/openid-connect/userinfo
      role_attribute_path: contains(groups[*], 'admin') && 'Admin' || 'Viewer'
  envFromSecret: grafana-oauth
```

`grafana-oauth` ExternalSecret fetches `keycloak/grafana-client-secret` from Vault.
Added to `infra/keycloak-config/`.

### Step 5: ArgoCD SSO

ArgoCD OIDC config in `infra/argocd/` (raw ConfigMap patch or values if using Helm).
ArgoCD is currently deployed via bootstrap, not Helm — raw manifest patch.

ArgoCD `argocd-cm` additions:
```yaml
oidc.config: |
  name: Keycloak
  issuer: https://keycloak.homelab/realms/homelab
  clientID: argocd
  clientSecret: $oidc.keycloak.clientSecret
  requestedScopes: ["openid", "profile", "email", "groups"]
```

`argocd-secret` gets key `oidc.keycloak.clientSecret` injected via ESO.

### Step 6: Realm bootstrap

Keycloak realm + clients cannot be bootstrapped purely via Helm values (chart supports
some env-based config, not full client creation). Options:
1. Manual via Keycloak UI after deploy (acceptable for homelab)
2. `keycloak-config-cli` init job (bitnami chart supports this)

**Decision:** Use bitnami's built-in `keycloakConfigCli` to bootstrap realm + clients
from a ConfigMap baked into the Helm values. This keeps everything in git.

---

## Execution Order

1. Write `infra/keycloak/values.yaml` (propose structure, wait for approval)
2. Write `apps/keycloak.yaml`
3. Write `infra/keycloak-config/keycloak-external-secret.yaml`
4. Write `apps/keycloak-config.yaml`
5. Update `infra/monitoring/values.yaml` (Grafana OIDC)
6. Add ESO ExternalSecret for grafana-oauth secret
7. Patch ArgoCD OIDC config
8. Validate all Helm templates
9. Commit and push

---

## Open Questions (to resolve before executing)

1. **Keycloak hostname:** `keycloak.homelab` — confirmed by phase-log task description.
2. **PostgreSQL:** Use bundled sub-chart (bitnami). Single replica, standard StorageClass, 2Gi PVC.
3. **Realm bootstrap:** Use `keycloakConfigCli` jobs in Helm values — keeps realm JSON in git.
4. **ArgoCD deploy method:** ArgoCD itself is managed via the `bootstrap/` scripts, not a Helm app.
   Patching `argocd-cm` will be done via a raw manifest in `infra/argocd/` tracked by an ArgoCD Application.
   (Currently `apps/argocd-ingress.yaml` handles the ingress only — we'll add an `argocd-config` app
   or add the OIDC patch to the existing pattern.)

---

## Risks

- Keycloak + PostgreSQL is the heaviest workload yet. minikube on M4 Max (128GB) should handle it.
- `keycloakConfigCli` realm JSON must be correct on first sync — failures require manual Vault cleanup.
- ArgoCD OIDC: once enabled, the ArgoCD UI will require Keycloak to be up. Local admin bypass
  via `argocd admin` CLI still works.
- cert-manager TLS for `keycloak.homelab` follows same pattern as vault.homelab — no new risk.
