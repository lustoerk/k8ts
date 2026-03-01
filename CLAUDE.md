# CLAUDE.md

This file is operational context for Claude Code agents working in this repo.
It is not human documentation. Do not modify it unless asked.

## What This Repo Is

Single-tenant homelab Kubernetes cluster on minikube (macOS, qemu2 driver).
Fully declarative GitOps via ArgoCD. No legacy systems.

## Repo Structure

apps/       # ArgoCD Application manifests (App-of-Apps pattern)
infra/      # Helm values files, per-service subdirectories
bootstrap/  # bootstrap.sh and one-time setup scripts
docs/       # ADRs, context-block.md, repo-structure.md, task plans
- Check `docs/repo-structure` for more details

## Current Phase

Check `docs/context-block.md` for current phase, state, and blockers.
Do not assume phase status from file presence alone.

## Architecture Decisions

- App-of-Apps pattern; wave-based sync ordering
- cert-manager CRDs and issuers are separate ArgoCD Applications (not sync waves)
- SeaweedFS via FUSE/hostPath — not CSI
- Helm for all packaged workloads; raw manifests only for glue (namespaces, secrets)
- Plain Kubernetes Secrets now; SOPS planned; Vault deferred
- ArgoCD Application names must match the Helm release name
- Check `docs/adrs/` for more details

## Code Conventions

- Helm values: kebab-case keys, match upstream chart conventions
- One namespace per service — no shared namespaces
- All manifests go through ArgoCD — never `kubectl apply` in steady state
- Bash scripts: `set -euo pipefail`, no bashisms beyond macOS/Ubuntu common subset

## Known Pitfalls

- minikube + qemu2: file mounts behave differently than Docker driver
- SeaweedFS FUSE: use `--mount-string` or hostPath, not a CSI driver
- cert-manager: use a separate ArgoCD Application for issuers — sync waves are unreliable for CRD ordering
- ArgoCD Helm chart: upstream uses `server.` prefix in values — easy to miss
- minikube tunnel + qemu2: LoadBalancer EXTERNAL-IP stays as ClusterIP, not 127.0.0.1 — /etc/hosts must use the ClusterIP
- Do NOT use `.local` TLD for homelab hostnames — macOS reserves `.local` for mDNS (Bonjour)
- Large Helm CRDs (kube-prometheus-stack, ESO): ArgoCD's `ServerSideApply=true` syncOption does NOT apply to CRDs in a chart's `crds/` directory — those always use client-side apply and hit the 262144-byte annotation limit. Fix: `helm.skipCrds: true` in the Application + one-time `helm template --include-crds | kubectl apply --server-side`

## Behavior Rules

**Never do without being explicitly asked:**
- `kubectl apply` anything directly
- Force-sync an ArgoCD Application that is **Healthy + OutOfSync** — this state is often benign (floating chart version, label drift). Investigate with `argocd app diff` first; never patch/force-sync blindly.
- Force-sync any Application with `prune: true` without first confirming via diff what would be pruned.

**Always do:**
- Run `helm template` at minimum before declaring a task done
- Stop and ask when a Helm chart value is ambiguous or a decision isn't covered by the ADRs
- After two failed recovery attempts on the same error, stop, declare a DEBT entry, and move on. Do not loop.

**Troubleshooting exit rule:**
If the same error persists after two distinct fix attempts, treat it as deferred debt unless it is blocking the current phase goal. Ask the user before attempting a third approach.

**Never do unprompted:**
- Create README or documentation files
- Add "in production you'd want..." caveats
- Suggest cloud-managed alternatives (EKS, AKS, GKE, etc.)
- Verify against upstream chart values.yaml unless explicitly asked

## Task Execution

**Single-file tasks** (namespace manifest, ArgoCD Application manifest):
Execute autonomously.

**Multi-step tasks** (new phase scaffold, debugging session):
1. Write a plan to `docs/task-<slug>.md`
2. Wait for explicit approval
3. Execute, then move the task plan file to `/docs/completed` when done

**Helm values files from scratch:**
Do not generate autonomously — propose structure and wait for approval.

## Phase Log

`docs/phase-log.md` is the running record for the **current** phase.
Completed phases are moved to `docs/history/phase-X.md`.

**Always do:**
- When a bug is encountered and fixed during any task, append a BUG-XX entry to the current phase section before closing the task.
- When unplanned work creates future obligation, append a DEBT-XX entry.
- When a phase is completed, execute all steps in order:
    1. Mark all its tasks as done in `docs/phase-log.md`.
    2. Move the phase content to `docs/history/phase-N.md`.
    3. Update `docs/contextblock.md` (phase, state, blockers, next phase).
    4. Update `docs/understanding/system-map.md`: move newly-active services out of Deferred, add anything newly deferred.
    5. Update `docs/understanding/argocd-model.md` if the ArgoCD topology changed (new wave, new Application pattern).
    6. Add any new ADRs for decisions made during the phase.
    7. Start the next phase section in `docs/phase-log.md`.

**Format:** Match the existing entries in `docs/phase-log.md` exactly (task checklist, bug with Symptom/Fix, debt item).

## Validation

After generating or modifying any Helm values file or ArgoCD Application:
- Run `helm template <release> <chart> -f <values-file>` and confirm it renders without error
- Report the output summary (not the full render unless asked)