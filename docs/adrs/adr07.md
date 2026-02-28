ADR 007 — Ingress
Context
minikube has a built-in ingress addon (nginx-based), or ingress-nginx can be
installed via Helm and managed by ArgoCD.
Decision
ingress-nginx via Helm, managed by ArgoCD.
Rationale
ArgoCD-managed ingress is closer to the production pattern. minikube addon
is convenient but hides configuration and isn't GitOps-managed.
Note
minikube tunnel is required to expose LoadBalancer services on macOS. This
needs to run in a separate terminal during development.