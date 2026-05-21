# ADR 005 — Storage Strategy (Unchanged)

## Context

minikube's built-in standard StorageClass (hostpath provisioner) for any
platform components that need PVCs. SeaweedFS deployed independently with its
own StorageClass for experimentation.

## Decision

minikube's built-in standard StorageClass (hostpath provisioner) for any
platform components that need PVCs. SeaweedFS deployed independently with its
own StorageClass for experimentation.

## Tradeoffs Accepted

- hostPath storage is not durable across minikube delete. Data is VM-local.
- Acceptable for homelab that rebuilds periodically.
- Not suitable for production use.

## Status

**Superseded by [ADR-011](adr11-professionalization-roadmap.md)** — Declarative DNS and Disaster Recovery deferred to Phase 8.
