# Phase 6: Redis Operator Deployment

**Status:** COMPLETED  
**Date:** 2026-05-20  
**Ticket:** ITCTEPE-98

## Overview

Successfully deployed the OT-CONTAINER-KIT Redis Operator as the first application-layer workload on the hardened platform via ArgoCD/Helm.

## CRDs Registered

The operator registers the following Custom Resource Definitions:

| CRD | Description |
|-----|-------------|
| `Redis` | Single Redis instance |
| `RedisCluster` | Redis cluster with multiple nodes |
| `RedisReplication` | Redis replication setup |
| `RedisSentinel` | Redis Sentinel for high availability |

## Smoke Test Results

Successfully created and deleted a test Redis instance to verify operator functionality.

## Challenges

| Issue | Resolution |
|-------|------------|
| Chart v0.25.0 unavailable | Used v0.24.0 instead |
| quay.io Docker daemon timeout | Pulled image manually: `docker pull quay.io/opstree/redis-operator:v0.24.0 && minikube image load ...` |
| redis-exporter AMD64-only | Excluded from test deployment (`nodeSelector: kubernetes.io/arch: arm64`) |
| webhook/cert-manager conflict | Disabled both webhooks in values |

## Files Created

- `apps/redis-operator.yaml` — ArgoCD Application manifest
- `infra/redis-operator/values.yaml` — Helm values file

## Next Steps

Phase 7 — Deploy a Redis instance and integrate with SeaweedFS for storage backend.
