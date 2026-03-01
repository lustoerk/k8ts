ADR 009 — Vault Deployment Model
Context
Phase 3 introduces HashiCorp Vault for centralized secrets management. The
cluster is single-node minikube with hostPath storage. Vault supports several
deployment models: dev mode, standalone (file storage), and HA (Raft, multi-replica).
Decision
Standalone mode with file storage backend (single replica, hostPath PVC via
`standard` StorageClass).
Rationale
Dev mode is ephemeral and not appropriate for any persistent secret storage.
Standalone with file storage is the simplest production-like deployment — one
StatefulSet replica, one PVC, no Raft quorum complexity. On a single-node
minikube cluster there is no benefit to HA (Raft requires at least 3 replicas
and minikube has one node).
Vault internal TLS is disabled — ingress-nginx terminates TLS via cert-manager.
Vault UI is enabled, exposed via ingress at `vault.homelab`.
Constraints Accepted
Sealed on restart: Vault starts sealed after every pod restart (including
after `minikube stop`/`start`). Must be manually unsealed with 2 of 3 unseal
keys before ESO or any secret consumer can access secrets.
Data loss on minikube delete: hostPath PVC is VM-local. `minikube delete`
destroys all Vault data. Re-init and re-populate secrets after every full
cluster rebuild.
No HA: a pod crash interrupts all secret access until the pod restarts and
is manually unsealed. No auto-unseal (HSM/cloud KMS) configured.
Unseal key management: keys must be stored offline (password manager, not in
git). Loss of 2 keys = permanent inaccessibility of all secrets.
Future
Vault HA (Raft, 3 replicas) and auto-unseal via cloud KMS can be introduced
in a later phase if the cluster is expanded. Out of scope for Phase 3.
