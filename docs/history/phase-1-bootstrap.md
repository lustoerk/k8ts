# Phase 1 — Bootstrap & Initial Sync

**Date:** 2026-02-28

### Tasks

- [x] Run `bootstrap/bootstrap.sh` — minikube start, ArgoCD install, root App-of-Apps applied
- [x] Create GitHub repo-creds secret for ArgoCD
- [x] Verify ArgoCD syncs all Phase 1 applications: cert-manager, cert-manager-issuers, ingress-nginx, seaweedfs

### Bugs / Unplanned Work

**BUG-01 — ArgoCD repo secret type wrong**
- Bootstrap script creates secret with label `argocd.argoproj.io/secret-type: repo-creds` (credential template, used for many repos sharing a URL prefix).
- For a single private repo, the correct type is `repository`.
- Symptom: `authentication required: Repository not found`
- Fix: Delete `repo-creds` secret, create new `argocd-repo-k8ts` secret with `secret-type: repository`.

**BUG-02 — Fine-grained PAT requires GitHub username, not "git"**
- Bootstrap script hardcodes `username=git` in the secret creation instructions.
- Fine-grained PATs authenticate with the actual GitHub username.
- Symptom: `Invalid username or token. Password authentication is not supported for Git operations.`
- Fix: Patch secret `username` field to `lustoerk`.

**BUG-03 — Scaffold commits not pushed before bootstrap**
- Commits containing `apps/` and `infra/` were local only; remote was at the `init` commit.
- ArgoCD could authenticate but found an empty repo at the configured path.
- Symptom: `app path does not exist`
- Fix: `git push origin main`

**BUG-04 — Read-only PAT blocked local push**
- Fine-grained PAT was scoped to Contents: Read-only (correct for ArgoCD).
- Local git remote also used this PAT, so push was rejected.
- Symptom: `remote: Write access to repository not granted`
- Fix: Upgraded PAT to Contents: Read and write for local pushes. ArgoCD secret is unaffected.

**BUG-05 — SeaweedFS pods stuck Pending (wrong arch nodeSelector)**
- SeaweedFS Helm chart defaults `nodeSelector` to `kubernetes.io/arch: amd64`.
- minikube on Apple M4 Max (qemu2) runs as `arm64`.
- Symptom: `0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector`
- Fix: Added `nodeSelector: | kubernetes.io/arch: arm64` to master, volume, and filer in `infra/seaweedfs/values.yaml`.

**BUG-06 — SeaweedFS nodeSelector is a multiline string, not a YAML map**
- Chart uses `tpl` to render `nodeSelector`, so the value must be a YAML block string, not a map.
- Symptom: Helm warnings `destination for nodeSelector is a table. Ignoring non-table value`, nodeSelector silently dropped from rendered manifests.
- Fix: Use `nodeSelector: |` (block scalar) instead of a nested map.

**BUG-07 — StatefulSet pods not recreated after spec change**
- Updating a StatefulSet spec (nodeSelector) does not automatically delete existing pods.
- Pods were in Pending state (never scheduled), so there was no rolling update to trigger.
- Symptom: Pods continued showing old `amd64` nodeSelector after ArgoCD synced the updated StatefulSet.
- Fix: Manual `kubectl delete pod` on all three seaweedfs pods; controller recreated them with the updated spec.

### Tech Debt

- **DEBT-01:** `bootstrap.sh` secret instructions use `username=git` — will fail for fine-grained PATs. Should be updated to prompt for or accept the actual GitHub username.
- **DEBT-02:** No liveness/readiness probe validation after initial sync. Confirmed pods Running/Ready visually but no automated health assertion.
- **DEBT-03:** SeaweedFS `nodeSelector` override is a workaround for an upstream chart default that assumes amd64. Should watch for upstream fix or consider contributing a patch.
