# Phase Log

Forward-looking roadmap. Completed phases live in [`history/`](history/). Active session state lives in [`.scratch/LOG.md`](../.scratch/LOG.md).

## Completed

- [Phase 0 — Prerequisites & Scaffold](history/phase-0-prereq.md)
- [Phase 1 — Bootstrap & Initial Sync](history/phase-1-bootstrap.md)
- [Phase 2 — Monitoring (Prometheus + Grafana)](history/phase-2-monitoring.md)
- [Phase 3 — Vault + ESO](history/phase-3-vault.md)
- [Phase 4 — Keycloak SSO](history/phase-4-keycloak.md)
- [Phase 4 Review — Professionalization Roadmap](adrs/adr11-professionalization-roadmap.md)
- [Phase 5 — Resource Limits & Requests](history/phase-5-resources.md)
- [Phase 6 — Redis Operator](history/phase-6-redis-operator.md)

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
