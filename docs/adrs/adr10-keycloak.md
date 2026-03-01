ADR 010 — Keycloak Deployment Model and SSO Integration

Context
Phase 4 introduces Keycloak as the homelab SSO provider. Design choices were
needed for chart, image, realm bootstrap strategy, and client wiring for
Grafana and ArgoCD.

Decision

Chart: codecentric/keycloakx 7.1.8. The Bitnami keycloak chart was originally
planned but replaced mid-phase after it was found to be incompatible with the
official Keycloak image entrypoint (see BUG-02). keycloakx is designed for the
official quay.io/keycloak/keycloak image and exposes the Keycloak CLI args
directly.

Image: quay.io/keycloak/keycloak:26.5.3 (chart appVersion).

Database: plain Kubernetes StatefulSet (PostgreSQL 16) in the same namespace.
The keycloakx chart's bundled postgresql sub-chart was not used; a standalone
StatefulSet is simpler to inspect and debug. Credentials managed by Vault + ESO.

Realm bootstrap: init container (`realm-import-prep`) using Alpine + envsubst
substitutes Vault-backed client secrets into a realm JSON template stored in a
ConfigMap, writing the result to an emptyDir volume mounted at
`/opt/keycloak/data/import`. Keycloak's `--import-realm` flag picks this up
on first startup. IGNORE_EXISTING strategy means re-deploys are safe.

Hostname: `KC_HOSTNAME=https://keycloak.homelab` (full URL). Keycloak 26 uses
hostname v2 SPI where KC_HOSTNAME accepts a scheme, pinning the OIDC issuer to
`https://` without relying on proxy forwarded headers.

Grafana OAuth: generic_oauth with PKCE S256. Backchannel URLs (token_url,
api_url) use the in-cluster service DNS; auth_url uses the public hostname
(browser-facing). root_url set to `https://graf.homelab` so Grafana constructs
the correct redirect_uri.

ArgoCD OIDC: direct OIDC (no Dex). keycloak.homelab resolved in-cluster via a
CoreDNS hosts entry (kube-system/coredns ConfigMap). Homelab CA cert added as
rootCA in argocd-cm oidc.config to trust the self-signed TLS certificate.
RBAC: groups claim maps Keycloak group `admin` → ArgoCD role:admin.

Constraints Accepted
Realm is re-imported on every pod restart with IGNORE_EXISTING — existing
user data, credentials, and configuration added after initial import are
preserved, but the import JSON is not a live sync. Changes to clients or groups
require either a manual kcadm update or a pod restart with a modified ConfigMap.

CoreDNS hosts entry is imperative (kubectl patch), not GitOps-managed. It will
be lost on `minikube delete`. Re-apply after every full cluster rebuild.

Future
Keycloak HA (multi-replica + external DB) is out of scope for this homelab.
Auto-import of realm changes (e.g. keycloak-config-cli) could replace the
init-container approach if the realm grows significantly.
