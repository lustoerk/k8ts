# k8ts — AI Agent Context

Operational context for AI agents (OpenCode, Claude Code, etc.) working in this repo. Not human documentation. Do not modify unless asked.

## What This Repo Is

Single-tenant homelab Kubernetes cluster on minikube (macOS, qemu2 driver). Fully declarative GitOps via ArgoCD. No legacy systems.

## Repo Structure

```
apps/       ArgoCD Application manifests (App-of-Apps pattern)
infra/      Helm values files, per-service subdirectories
bootstrap/  bootstrap.sh and one-time setup scripts
docs/       ADRs, phase-log (roadmap), history, architecture notes
.scratch/   Session state (LOG.md) and ephemeral task plans
```

## Session State

- **Active state + recent sessions** → `.scratch/LOG.md` (canonical session log; `## Current` block at top holds the active problem).
- **Multi-step plans** → `.scratch/YYYY-MM-DD-<slug>.md` (ephemeral; delete after the work merges).
- **Decisions** → `docs/adrs/` (one ADR per non-trivial choice).
- **Roadmap** → `docs/phase-log.md` (forward-looking only; completed phases live in `docs/history/`).

## Documentation Hierarchy (Single Source of Truth)

To prevent documentation drift, responsibilities are strictly separated:

| Document | Responsibility | NEVER Contains |
|----------|---------------|----------------|
| `.scratch/LOG.md` | **Only** current phase state | Future roadmap, historical records |
| `docs/phase-log.md` | Forward roadmap (phases not started) | "Current" markers, completed work |
| `docs/history/phase-*.md` | Completed phase records | Active work, future plans |
| `README.md` | Human onboarding + stack overview | Detailed phase task lists |
| `AGENTS.md` | Agent conventions + pitfalls | Status, roadmap |

**On phase completion:**
1. `/done` updates `.scratch/LOG.md`
2. Manually move phase from `phase-log.md` → `history/phase-*.md`
3. Update `system-map.md` deployment table
4. README.md NEVER contains detailed phase lists—only links

## Architecture Decisions

- App-of-Apps pattern; wave-based sync ordering
- cert-manager CRDs and issuers are separate ArgoCD Applications (not sync waves)
- SeaweedFS via FUSE/hostPath — not CSI
- Helm for all packaged workloads; raw manifests only for glue (namespaces, secrets)
- Plain Kubernetes Secrets initially; secrets now via Vault + ESO
- ArgoCD Application names must match the Helm release name
- See `docs/adrs/` for the full set

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
- minikube tunnel + qemu2: LoadBalancer EXTERNAL-IP stays as ClusterIP, not 127.0.0.1 — `/etc/hosts` must use the ClusterIP
- Do NOT use `.local` TLD for homelab hostnames — macOS reserves `.local` for mDNS (Bonjour); use `.homelab`
- Large Helm CRDs (kube-prometheus-stack, ESO): ArgoCD's `ServerSideApply=true` syncOption does NOT apply to CRDs in a chart's `crds/` directory — those always use client-side apply and hit the 262144-byte annotation limit. Fix: `helm.skipCrds: true` in the Application + one-time `helm template --include-crds | kubectl apply --server-side`

## Behavior Rules

**Never do without being explicitly asked:**

- `kubectl apply` anything directly
- Force-sync an ArgoCD Application that is **Healthy + OutOfSync** — this state is often benign (floating chart version, label drift). Investigate with `argocd app diff` first; never patch/force-sync blindly.
- Force-sync any Application with `prune: true` without first confirming via diff what would be pruned.

**Always do:**

- Run `helm template` at minimum before declaring a task done
- Stop and ask when a Helm chart value is ambiguous or a decision isn't covered by the ADRs
- After two failed recovery attempts on the same error, stop, declare a debt entry in `.scratch/LOG.md`, and move on. Do not loop.

**Troubleshooting exit rule:**

If the same error persists after two distinct fix attempts, treat it as deferred debt unless it is blocking the current phase goal. Ask the user before attempting a third approach.

**Never do unprompted:**

- Create README or documentation files
- Add "in production you'd want..." caveats
- Suggest cloud-managed alternatives (EKS, AKS, GKE, etc.)
- Verify against upstream chart values.yaml unless explicitly asked

## Task Execution

**Single-file tasks** (namespace manifest, ArgoCD Application manifest): execute autonomously.

**Multi-step tasks** (new phase scaffold, debugging session):

1. Write a plan to `.scratch/YYYY-MM-DD-<slug>.md`
2. Wait for explicit approval
3. Execute, then delete the plan file when the work merges

**Helm values files from scratch:** do not generate autonomously — propose structure and wait for approval.

## Validation

After generating or modifying any Helm values file or ArgoCD Application:

- Run `helm template <release> <chart> -f <values-file>` and confirm it renders without error
- Report the output summary (not the full render unless asked)