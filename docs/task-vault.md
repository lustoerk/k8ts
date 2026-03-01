# Task Plan — Phase 3: Vault + ESO

## Learnings from First Attempt (2026-03-01)

- **ESO CRD size issue**: `ServerSideApply=true` is required on the `external-secrets`
  Application. Without it, ArgoCD silently drops `SecretStore` and `ClusterSecretStore`
  CRDs because their schemas exceed the `last-applied-configuration` annotation limit.
  Add this syncOption before first sync.

- **Two-step ArgoCD sync required for Application changes**: Changing syncOptions on
  a child Application (`apps/external-secrets.yaml`) requires syncing the ROOT app first
  to update the Application object, then syncing the child app. Refreshing only the child
  app picks up stale syncOptions from the cluster object.

- **Cert-controller readiness probe**: After the CRD race condition, the cert-controller
  may show `"ca cert not yet ready"` errors. Bouncing the webhook pod resolves it once
  the main controller is stable.

- **Vault bootstrap is manual-heavy**: The init/unseal/auth-enable/policy/role sequence
  is disruptive to do interactively via `kubectl exec`. Consider scripting the vault
  bootstrap into `bootstrap/vault-init.sh` for the next attempt.

- **Vault was already initialized** when bootstrap was attempted — Vault must have
  auto-initialized from a previous `minikube start` and PVC reuse. Check
  `vault status` before running `vault operator init`.

---

## Scope

Deploy HashiCorp Vault (standalone, manual unseal) and External Secrets Operator.
Wire them together via Kubernetes auth. Validate end-to-end by migrating the
Grafana admin password out of plaintext values.yaml into Vault.

## Chart Versions

- `hashicorp/vault` 0.32.x (Vault 1.21.x)
- `external-secrets/external-secrets` 2.0.x

## Files to Create

```
apps/vault.yaml
apps/external-secrets.yaml
apps/vault-config.yaml
infra/vault/values.yaml
infra/external-secrets/values.yaml
infra/vault-config/cluster-secret-store.yaml
infra/vault-config/grafana-external-secret.yaml
```

## Sync Wave Design

| Wave | App |
|------|-----|
| 2 | seaweedfs, monitoring (existing) |
| 3 | vault, external-secrets |
| 4 | vault-config (manual sync — only after Vault is initialized) |

`vault-config` must not auto-sync. It contains the ClusterSecretStore and
ExternalSecret manifests, which will fail if applied before Vault is initialized
and the Kubernetes auth method is configured. Set `automated: {}` with no prune/selfHeal;
sync it manually from the ArgoCD UI after the bootstrap steps below.

---

## Step 1 — Create `apps/vault.yaml` and `infra/vault/values.yaml`

Key decisions in values:
- Standalone mode (single replica, file storage backend)
- Internal TLS **disabled** — ingress-nginx terminates TLS via cert-manager
- hostPath PVC via `standard` StorageClass for `/vault/data`
- Vault UI enabled, exposed via ingress at `vault.homelab.local`
- arm64 nodeSelector

## Step 2 — Create `apps/external-secrets.yaml` and `infra/external-secrets/values.yaml`

Minimal install. ESO runs in its own namespace (`external-secrets`).
arm64 nodeSelector on all components.

## Step 3 — Validate and push

```
helm template vault hashicorp/vault -f infra/vault/values.yaml
helm template external-secrets external-secrets/external-secrets \
  -f infra/external-secrets/values.yaml
```

Push → ArgoCD syncs wave 3 → Vault pod starts (sealed), ESO pods start.

## Step 4 — Bootstrap Vault (manual, run once)

```bash
# Exec into the Vault pod
kubectl exec -it vault-0 -n vault -- vault operator init \
  -key-shares=3 -key-threshold=2

# SAVE the output: 3 unseal keys + root token (store offline)

# Unseal (run twice with two different unseal keys)
kubectl exec -it vault-0 -n vault -- vault operator unseal <KEY_1>
kubectl exec -it vault-0 -n vault -- vault operator unseal <KEY_2>

# Login
kubectl exec -it vault-0 -n vault -- vault login <ROOT_TOKEN>

# Enable KV secrets engine
kubectl exec -it vault-0 -n vault -- vault secrets enable -path=secret kv-v2

# Enable Kubernetes auth
kubectl exec -it vault-0 -n vault -- vault auth enable kubernetes
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

# Create ESO policy
kubectl exec -it vault-0 -n vault -- vault policy write eso-policy - <<EOF
path "secret/data/*" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes auth role for ESO
kubectl exec -it vault-0 -n vault -- vault write auth/kubernetes/role/eso-role \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=eso-policy \
  ttl=1h

# Write the Grafana admin password to Vault
kubectl exec -it vault-0 -n vault -- vault kv put secret/grafana admin-password=homelab
```

## Step 5 — Create vault-config manifests

`infra/vault-config/cluster-secret-store.yaml` — ClusterSecretStore pointing to Vault,
using Kubernetes auth, role `eso-role`.

`infra/vault-config/grafana-external-secret.yaml` — ExternalSecret in the `monitoring`
namespace, reading `secret/grafana` from Vault, syncing to K8s Secret `grafana-admin`.

## Step 6 — Create `apps/vault-config.yaml` and sync manually

Push vault-config Application to git. **Do not auto-sync.**
After Vault bootstrap steps are done: sync from ArgoCD UI.
Confirm K8s Secret `grafana-admin` appears in `monitoring` namespace.

## Step 7 — Update Grafana values

Remove `adminPassword: homelab` from `infra/monitoring/values.yaml`.
Add:
```yaml
grafana:
  admin:
    existingSecret: grafana-admin
    userKey: admin-user     # ESO will not set this; use default key name from chart
    passwordKey: admin-password
```

Push → ArgoCD syncs monitoring → Grafana restarts using secret from Vault.

## Step 8 — Verify

- Grafana login works with password stored in Vault
- `vault kv get secret/grafana` returns the password
- ESO ExternalSecret shows `Ready` status
- Vault UI accessible at `https://vault.homelab.local`

---

## Operational Note — Unsealing After Restarts

Vault starts sealed after every pod restart. Add to runbook:
```bash
kubectl exec -it vault-0 -n vault -- vault operator unseal <KEY_1>
kubectl exec -it vault-0 -n vault -- vault operator unseal <KEY_2>
```
No data is lost — only access is blocked until unsealed.

## Risks

- **arm64 images**: Vault 1.21.x official image is multi-arch. ESO 2.0.x is also multi-arch. Verify during `helm template`.
- **vault-config sync timing**: ClusterSecretStore will error if synced before Vault K8s auth is configured. Controlled by manual sync — do not enable automated sync on `vault-config`.
- **Grafana existingSecret key names**: chart expects specific key names (`admin-user`, `admin-password`) — must match what ESO writes into the K8s Secret.
- **ESO ServiceAccount name**: confirm ESO deploys its SA as `external-secrets` in namespace `external-secrets` — this is the default but verify against rendered chart before writing the Vault role.

## Done When

- Vault Synced/Healthy in ArgoCD, UI accessible, unsealed
- ESO Synced/Healthy
- ExternalSecret `grafana-admin` shows Ready
- Grafana login works, no plaintext password in git
- Phase 3 tasks checked off in `docs/phase-log.md`
