# Homelab K8s Design — v2 (Minimal Stack)

## Bootstrap Sequence

```
bootstrap.sh:
  1. minikube start --driver=qemu2 --memory=16384 --cpus=4 --disk-size=50g
  2. minikube addons enable metrics-server (optional, lightweight)
  3. helm repo add argo https://argoproj.github.io/argo-helm
  4. helm install argocd argo/argo-cd -n argocd --create-namespace \
       --set server.service.type=NodePort \
       --set configs.params."server\.insecure"=true
  5. kubectl wait --for=condition=available deployment/argocd-server -n argocd
  6. Create argocd-repo-creds Secret (GitHub PAT)
  7. kubectl apply -f root-app.yaml
```

That's it. Everything after step 7 is ArgoCD syncing from GitHub.

---

## ArgoCD Sync Waves

```
Wave 1: cert-manager (+ ClusterIssuer once CRDs ready)
Wave 2: ingress-nginx
Wave 3: seaweedfs
```

Three waves. cert-manager before ingress because Ingress resources may
reference TLS certificates. SeaweedFS last because it has no dependents.

### Sync Wave Notes
- cert-manager needs a post-sync hook or separate Application for ClusterIssuer
  resources, since CRDs must be registered before custom resources can be
  applied. Options:
  A) Two ArgoCD Applications: cert-manager (wave 1), cert-manager-issuers (wave 1.5)
  B) Single Application with a sync-wave annotation on the ClusterIssuer manifests
  Option A is cleaner — CRD readiness is not guaranteed by sync wave ordering
  within a single Application.

---

## Component Summary

### ArgoCD
- Installed by bootstrap.sh (the one imperative component)
- Watches GitHub private repo via PAT-based repo credential
- NodePort + HTTP initially, Ingress + TLS added once cert-manager/ingress-nginx sync
- Self-management: ArgoCD Application pointing at its own chart added in
  growth path (not initial build — avoid self-management foot-guns early)

### cert-manager
- Helm chart via ArgoCD Application
- installCRDs: true
- ClusterIssuer chain: selfsigned-bootstrap → homelab-ca Certificate →
  homelab-ca ClusterIssuer
- Separate ArgoCD Application for issuers (see sync wave notes)

### ingress-nginx
- Helm chart via ArgoCD Application
- Default IngressClass
- minikube tunnel required for LoadBalancer access on macOS

### SeaweedFS
- Components: master (1), volume (1), filer (1), CSI driver
- S3 API enabled on filer (port 8333)
- StorageClass: seaweedfs-csi, replication "000"
- S3 credentials: plain k8s Secret (created by ArgoCD from manifest in repo)
- PVCs for master/volume/filer metadata: minikube hostpath StorageClass
- CSI node plugin needs FUSE access — minikube VM provides this natively

---

### Notes on Structure
- `bootstrap/` is the only directory used outside of GitOps. It's run once.
- `apps/` contains ArgoCD Application manifests. root-app.yaml points here.
- `infra/` contains per-component Helm values and raw manifests.
- No Kustomize initially. Plain manifests + Helm values. Kustomize is a
  growth path item.
- `s3-credentials-secret.yaml` contains a SealedSecret or SOPS-encrypted
  secret. If neither is set up yet, the secret is created manually once
  and ArgoCD is told to ignore it (or it's committed as a plain Secret with
  the understanding that this is a local-only repo). Decision point at build
  time.

---

## Ingress Hosts

```
argocd.k8s.local     → ArgoCD UI (after ingress syncs)
seaweedfs.k8s.local  → SeaweedFS master UI
filer.k8s.local      → SeaweedFS filer UI / S3 endpoint
```

### DNS Resolution on macOS
Option A: /etc/hosts entries (manual, no wildcard)
Option B: dnsmasq with wildcard *.k8s.local → $(minikube ip)

minikube's IP is not 127.0.0.1 with the qemu2 driver — it's a VM IP.
`minikube ip` returns it. /etc/hosts is simpler for three entries.
dnsmasq is better if the host list grows. Decide at build time.

---

## Active Risks

- [ ] SeaweedFS Helm chart maturity — pin version explicitly, check ARM
      compatibility on Apple Silicon
- [ ] minikube qemu2 driver stability on macOS — known to be less mature
      than Docker driver. Fallback: Docker driver with `--ports` flag
      (but reintroduces FUSE risk)
- [ ] SeaweedFS CSI on single-node — CSI node plugin and controller may
      have scheduling constraints. Verify tolerations if minikube node
      has taints.
- [ ] cert-manager CRD readiness — separate ArgoCD Application for issuers
      mitigates but doesn't eliminate timing issues. May need retry annotation.
- [ ] S3 credentials in Git — plain Secret in repo is a bad habit. Decide
      on SOPS or SealedSecrets before committing, or accept the risk for
      local-only use.

---

## Build Order

### Phase 0: Mac Setup
- [ ] Install minikube, helm, kubectl
- [ ] Verify qemu2 driver: `minikube start --driver=qemu2` smoke test
- [ ] Create GitHub private repo: homelab
- [ ] Generate GitHub PAT (repo scope) for ArgoCD

### Phase 1: Repo Skeleton
- [ ] Create directory structure per repo layout above
- [ ] Create .gitignore
- [ ] Create ADR docs (from this design)
- [ ] Push to GitHub

### Phase 2: bootstrap.sh
- [ ] Write bootstrap.sh per bootstrap sequence above
- [ ] Test: `./bootstrap.sh` → ArgoCD running, root-app applied
- [ ] Verify ArgoCD UI via NodePort (`minikube service argocd-server -n argocd`)

### Phase 3: cert-manager
- [ ] Create apps/cert-manager.yaml (ArgoCD Application, wave 1)
- [ ] Create infra/cert-manager/values.yaml
- [ ] Create apps/cert-manager-issuers.yaml (ArgoCD Application, wave 1.5)
- [ ] Create infra/cert-manager-issuers/ manifests
- [ ] Push → verify ArgoCD syncs → verify ClusterIssuer ready

### Phase 4: ingress-nginx
- [ ] Create apps/ingress-nginx.yaml (ArgoCD Application, wave 2)
- [ ] Create infra/ingress-nginx/values.yaml
- [ ] Push → verify ArgoCD syncs
- [ ] Start `minikube tunnel` → verify ingress reachable
- [ ] Add ArgoCD Ingress manifest with TLS → verify HTTPS access

### Phase 5: SeaweedFS
- [ ] Create apps/seaweedfs.yaml (ArgoCD Application, wave 3)
- [ ] Create infra/seaweedfs/ manifests and values
- [ ] Push → verify ArgoCD syncs → all pods running
- [ ] Verify master UI via ingress
- [ ] Test CSI: create PVC, mount in test pod, write/read
- [ ] Test S3: awscli from Mac against filer endpoint

### Phase 6: Post-Build Mac Setup
- [ ] Extract CA cert from cert-manager
- [ ] Add to Mac System keychain
- [ ] Add /etc/hosts entries (or dnsmasq)
- [ ] Verify TLS on all ingress hosts

### Phase 7: Smoke Tests
- [ ] ArgoCD UI accessible via HTTPS, all apps synced and healthy
- [ ] SeaweedFS master UI accessible
- [ ] SeaweedFS CSI: PVC bound, test pod can write/read
- [ ] SeaweedFS S3: `aws s3 ls` works against filer endpoint
- [ ] Certificates valid and trusted in browser

---

## Growth Path (Future Phases)

Each phase is a self-contained addition via GitOps:

1. **Monitoring** — kube-prometheus-stack, dashboards for SeaweedFS
2. **SOPS/SealedSecrets** — encrypt secrets in Git properly
3. **Vault + ESO** — centralized secrets, migrate plain Secrets
4. **GitLab** — self-hosted, migrate ArgoCD source from GitHub
5. **GitLab Runner** — depends on GitLab + secrets management
6. **Keycloak** — OIDC for ArgoCD, GitLab, Grafana
7. **Multi-node** — minikube node add or switch to k3d/kubeadm
8. **ArgoCD self-management** — ArgoCD manages its own chart
9. **Terraform** — Vault policies, Keycloak realms
10. **CKA prep** — kubeadm cluster, RBAC, NetworkPolicy, PDBs

---

## Session Context Block (for next session)

```
Date: 2025-02-28
Phase: Design v2 complete. Ready to enter Build.
Stack: minikube + ArgoCD + cert-manager + ingress-nginx + SeaweedFS
Git remote: GitHub (private repo)
Secrets: plain k8s Secrets (Vault deferred)
Blockers: none — design is self-consistent
Next action: Phase 0 + Phase 1 (Mac setup + repo skeleton)
```
