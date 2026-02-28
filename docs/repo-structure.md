homelab/
├── bootstrap/
│   ├── bootstrap.sh
│   └── root-app.yaml
├── docs/
│   └── adrs/
│       ├── 001-kubernetes-distribution.md
│       ├── 002-git-remote.md
│       ├── 003-secrets-management.md
│       ├── 004-bootstrap-strategy.md
│       ├── 005-storage-strategy.md
│       ├── 006-tls-strategy.md
│       └── 007-ingress.md
├── apps/
│   ├── cert-manager.yaml          # ArgoCD Application
│   ├── cert-manager-issuers.yaml  # ArgoCD Application (wave 1.5)
│   ├── ingress-nginx.yaml         # ArgoCD Application
│   └── seaweedfs.yaml             # ArgoCD Application
├── infra/
│   ├── cert-manager/
│   │   └── values.yaml
│   ├── cert-manager-issuers/
│   │   ├── selfsigned-bootstrap.yaml
│   │   ├── homelab-ca-certificate.yaml
│   │   └── homelab-ca-issuer.yaml
│   ├── ingress-nginx/
│   │   └── values.yaml
│   └── seaweedfs/
│       ├── values.yaml
│       ├── namespace.yaml
│       ├── storageclass.yaml
│       └── s3-credentials-secret.yaml
└── .gitignore