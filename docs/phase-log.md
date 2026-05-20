# Phase Log

Forward-looking roadmap. Completed phases live in [`history/`](history/). Active session state lives in [`.scratch/LOG.md`](../.scratch/LOG.md).

## Completed

- [Phase 0 — Prerequisites & Scaffold](history/phase-0.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2.md)
- [Phase 3 — Vault + ESO](history/phase-3.md)
- [Phase 4 — Keycloak SSO](history/phase-4.md)
- [Phase 4 Review — Professionalization Roadmap](adrs/adr11-professionalization-roadmap.md)

---

## Phase 5 — Resource Limits & Requests `<-- current`

**Date:** TBD

Implement DEBT-04: production-grade resource management across all workloads.

### Tasks

- [ ] Audit current resource usage across all pods (metrics-server / `kubectl top`)
- [ ] Define and apply CPU/memory requests and limits for all Helm-managed services
- [ ] Validate cluster stability under constrained resources
- [ ] Update Grafana dashboards to visualize resource usage vs. limits

### Bugs / Unplanned Work

### Tech Debt

---

## Phase 6 — Redis Operator

**Date:** TBD

Integrate the OT-CONTAINER-KIT Redis Operator as the first application-layer workload on the hardened platform.

### Tasks

- [ ] TBD

---

## Phase 7 — SeaweedFS Review & Integration

**Date:** TBD

Bring SeaweedFS from "deployed but unused" to a fully integrated, tested storage service.

### Tasks

- [ ] Enable S3 authentication (access key / secret key)
- [ ] Store S3 credentials in Vault, sync via ESO
- [ ] Enable SeaweedFS Prometheus metrics + add ServiceMonitor
- [ ] Build Grafana dashboard for SeaweedFS (capacity, request rate, latency)
- [ ] Expose SeaweedFS admin UI via ingress (`seaweedfs.homelab`)
- [ ] Evaluate Keycloak integration for admin UI access (OAuth2 proxy or native)
- [ ] Deploy a small test workload that reads/writes to the S3 endpoint
- [ ] Document S3 usage patterns for future workloads

---

## Phase 8 — Operational Hardening

**Date:** TBD

Close remaining tech debt and improve day-to-day operations.

### Tasks

- [ ] Declarative CoreDNS — replace manual `hosts` patching with GitOps-managed ConfigMap
- [ ] Vault auto-unseal or break-glass procedure
- [ ] Document "Bootstrap from Zero" disaster recovery runbook
- [ ] Persistent storage — mount macOS host folders into minikube for data survival across `minikube delete`
- [ ] `/etc/hosts` automation (script or LaunchAgent)

---

## Phase 9 — New Applications

**Date:** TBD

Only after the platform is hardened. Candidates:

- [ ] Forgejo or GitLab (self-hosted SCM + CI, Keycloak SSO)
- [ ] AI/ML workload using SeaweedFS S3 for model/data storage
- [ ] Additional Keycloak-integrated services as needed