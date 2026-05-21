# ADR 006 — TLS Strategy

## Context

Need TLS for ingress endpoints. cert-manager is lightweight and provides
good learning value.

## Decision

cert-manager with self-signed CA chain. Same two-step ClusterIssuer from v1:
selfsigned-bootstrap → homelab-ca → cluster-wide issuer. CA cert trusted on
Mac via security add-trusted-cert.

## Tradeoffs Accepted

Self-signed CA. Browsers will trust it via the Mac keychain. Not
publicly-trusted — irrelevant for local use.

## Status

**No change required.** Current implementation matches decision.
