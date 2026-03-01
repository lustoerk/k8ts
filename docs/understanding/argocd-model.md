# ArgoCD Model

How this repo's ArgoCD setup works. Concepts only — for commands, see the manifests.

---

## The Core Idea: GitOps

ArgoCD continuously compares two states:

- **Desired state**: what's in `main` on GitHub
- **Actual state**: what's running in the cluster

When they diverge, ArgoCD reconciles toward desired state. A git push is the only legitimate way to change the cluster.

---

## App-of-Apps

There are two tiers of ArgoCD Applications in this repo.

**Tier 1 — the root app** (`bootstrap/root-app.yaml`)

Applied once by hand during bootstrap. It watches the `apps/` directory in this repo. Every YAML file in `apps/` is an ArgoCD Application manifest. The root app's job is to create and manage those Application objects in the cluster.

**Tier 2 — the child apps** (`apps/*.yaml`)

Each child app manages one service (cert-manager, ingress-nginx, seaweedfs, etc.). Child apps are themselves managed by the root app — so adding a new service means adding a file to `apps/`, not running any kubectl commands.

The recursive structure: ArgoCD manages Applications that manage everything else.

---

## Sync Waves and Ordering

Sync waves control the order in which the root app processes child Applications.

The wave annotation lives on each child Application manifest:

```yaml
# apps/cert-manager.yaml
annotations:
  argocd.argoproj.io/sync-wave: "0"

# apps/cert-manager-issuers.yaml
annotations:
  argocd.argoproj.io/sync-wave: "1"

# apps/seaweedfs.yaml, apps/monitoring.yaml
annotations:
  argocd.argoproj.io/sync-wave: "2"
```

ArgoCD processes waves in ascending order and **waits for each wave to be healthy** before starting the next. This is a hard sequencing guarantee.

Current wave ordering:

| Wave | Apps |
|------|------|
| 0 | cert-manager |
| 1 | cert-manager-issuers, ingress-nginx, argocd-ingress |
| 2 | seaweedfs, monitoring |
| 3 | vault, external-secrets |
| 4 | vault-config (**manual sync only** — must not auto-sync before Vault is initialized and unsealed) |
| 5 | keycloak |
| 6 | keycloak-config |

---

## Why cert-manager-issuers Is a Separate Application

This is the non-obvious part.

cert-manager installs Custom Resource Definitions (CRDs) — `Issuer`, `ClusterIssuer`, `Certificate`, etc. These CRDs must be registered in the Kubernetes API before any Issuer resource can be applied. If you try to apply an Issuer before its CRD exists, Kubernetes rejects it with an "unknown resource" error.

The naive approach — put issuers inside the cert-manager Application with a later sync wave — is unreliable. ArgoCD does not guarantee CRDs are fully established (accepted by the API server) before it processes the next intra-app sync wave.

The reliable approach: make issuers a **separate Application** at wave 1. The root app's wave ordering guarantees cert-manager (wave 0) reaches Healthy — meaning its CRDs are registered — before cert-manager-issuers (wave 1) is even attempted.

The separation encodes the dependency at the Application level, where ArgoCD's health checks are authoritative.

---

## Multi-Source Apps

Most child apps use two sources rather than one:

```yaml
sources:
  - repoURL: https://github.com/lustoerk/k8ts.git
    targetRevision: main
    ref: values                          # this repo, aliased as $values
  - repoURL: https://charts.jetstack.io
    chart: cert-manager
    targetRevision: "1.14.x"
    helm:
      valueFiles:
        - $values/infra/cert-manager/values.yaml   # values from this repo
```

The upstream Helm chart comes from its own chart repository. The values overrides live in this repo under `infra/<service>/values.yaml`. ArgoCD merges them at sync time.

This keeps chart versions and our configuration clearly separated.

Some apps use a **third source** — a raw manifest path in this repo — for supplementary resources that don't belong in the Helm chart (e.g. custom Grafana dashboard ConfigMaps):

```yaml
sources:
  - repoURL: https://github.com/lustoerk/k8ts.git
    targetRevision: main
    ref: values
  - repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    ...
  - repoURL: https://github.com/lustoerk/k8ts.git
    targetRevision: main
    path: infra/monitoring/manifests     # raw manifests applied alongside the chart
```

**Important:** changes to a child Application's `sources` list only take effect after the **root app is synced** — the root app owns the Application objects in the cluster.

---

## The Causal Chain

```
git push to main
  → ArgoCD polls GitHub (default: every 3 minutes, or webhook-triggered)
    → computes diff between git and cluster
      → triggers sync on affected Application(s)
        → applies changed resources to cluster
          → reports Synced/Healthy or error
```

If a sync fails, the Application stays out-of-sync and ArgoCD retries. `selfHeal: true` means ArgoCD will also re-sync if something drifts in the cluster without a git change (e.g. someone runs kubectl manually).

---

## What ArgoCD Does Not Do

- Does not build images or run CI
- Does not manage the ArgoCD installation itself (that's bootstrap)
- Does not manage minikube or the node — only what runs on the cluster
