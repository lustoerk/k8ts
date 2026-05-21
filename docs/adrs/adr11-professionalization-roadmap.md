# ADR 011 — Phase 4 Review & Professionalization Roadmap

## Context
Following the completion of Phase 4 (Keycloak), a "Brutal Review" of the architecture was conducted to identify over-engineering, operational friction, and technical debt. The cluster is running on a high-spec M4 Max (128GB RAM), allowing for an "Enterprise Learning" (Goal A) approach.

## Review Findings & Decisions

### 1. Enterprise Focus (Goal A)
- **Decision:** Maintain the complex stack (Vault, Keycloak, SeaweedFS) despite the single-node environment.
- **Rationale:** The goal is to learn these specific tools for production applicability.

### 2. SeaweedFS (Storage)
- **Status:** Keep.
- **Goal:** Learn S3-compatible storage management for future AI model workloads.
- **Debt:** Currently uses `hostPath` for data persistence, which is tied to the VM lifecycle.

### 3. GitLab (SCM/CI)
- **Status:** Deferred indefinitely.
- **Decision:** Not a pressing issue. When implemented, evaluate **Forgejo** as a lighter OIDC-compliant alternative if resources become constrained.

### 4. Operational "Professionalization"
To move from "Homelab" to "Enterprise-Grade," the following improvements are prioritized:

| Priority | Item | Description |
| :--- | :--- | :--- |
| **High** | DEBT-04 (Resources) | Implement strict CPU/Memory requests/limits across all apps. |
| **Med** | Declarative DNS | Move from manual CoreDNS `hosts` patching to GitOps-managed ConfigMap. |
| **Med** | Disaster Recovery | Move `hostPath` mounts to macOS host disk for persistence across `minikube delete`. |
| **Low** | Vault Unseal | Move toward "Break-glass" procedures or "unseal-as-code" instead of manual re-unseal. |

## Strategy for Disaster Recovery (DR)
The "Definition of Success" for the homelab includes being prepared for an eventual "outage."
1. **Infrastructure as Code:** Everything is already in ArgoCD.
2. **Data Persistence:** Current state is volatile (minikube-internal). Plan is to mount macOS folders.
3. **Secrets:** Root-of-Trust (Vault) requires unseal keys stored securely in a local password manager.

## Phase 5 Completion

Phase 5 (Resource Limits & Requests / DEBT-04) completed 2026-05-20. See [Phase 5 history](../history/phase-5-resources.md) for full details including GAP-01/02 and BUG-10/11.

## Next Steps

**Phase 6** — Redis Operator: Integrate the OT-CONTAINER-KIT Redis Operator as the first application-layer workload on the hardened platform.

Remaining professionalization items (Declarative DNS, Disaster Recovery, Vault Unseal) deferred to Phase 8.
