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

## Behavior Rules

**Never do without being explicitly asked:**
- `kubectl apply` anything directly

**Always do:**
- Run `helm template` at minimum before declaring a task done
- Stop and ask when a Helm chart value is ambiguous or a decision isn't covered by the ADRs

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

`docs/phase-log.md` is the running record of all work done. Keep it current.

**Always do:**
- When a bug is encountered and fixed during any task, append a BUG-XX entry to the current phase section before closing the task.
- When unplanned work creates future obligation, append a DEBT-XX entry.
- When a phase is completed, mark all its tasks as done and update `docs/contextblock.md`.

**Format:** Match the existing entries in `docs/phase-log.md` exactly (task checklist, bug with Symptom/Fix, debt item).

## Validation

After generating or modifying any Helm values file or ArgoCD Application:
- Run `helm template <release> <chart> -f <values-file>` and confirm it renders without error
- Report the output summary (not the full render unless asked)