ADR 005 — Storage Strategy (Unchanged)
Decision
minikube's built-in standard StorageClass (hostpath provisioner) for any
platform components that need PVCs. SeaweedFS deployed independently with its
own StorageClass for experimentation.