#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/lustoerk/k8ts.git"
ARGOCD_NAMESPACE="argocd"

echo "==> Starting minikube"
proxy_args=()
[[ -n "${HTTP_PROXY:-}"  ]] && proxy_args+=(--docker-env "HTTP_PROXY=${HTTP_PROXY}")
[[ -n "${HTTPS_PROXY:-}" ]] && proxy_args+=(--docker-env "HTTPS_PROXY=${HTTPS_PROXY}")
[[ -n "${NO_PROXY:-}"    ]] && proxy_args+=(--docker-env "NO_PROXY=${NO_PROXY}")

minikube start --driver=qemu2 --memory=16384 --cpus=4 --disk-size=50g \
    ${proxy_args[@]+"${proxy_args[@]}"}

echo "==> Enabling metrics-server addon"
minikube addons enable metrics-server

echo "==> Adding Argo Helm repo"
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "==> Installing ArgoCD"
helm upgrade --install argocd argo/argo-cd \
  -n "${ARGOCD_NAMESPACE}" --create-namespace \
  -f "$(dirname "$0")/../infra/argocd/values.yaml"

echo "==> Waiting for argocd-server"
kubectl wait --for=condition=available deployment/argocd-server \
  -n "${ARGOCD_NAMESPACE}" --timeout=300s

echo ""
echo "ACTION REQUIRED: Create the ArgoCD repository secret."
echo "Run the following (replace <TOKEN> and <USERNAME> with your GitHub details):"
echo ""
echo "  kubectl create secret generic argocd-repo-k8ts \\"
echo "    -n argocd \\"
echo "    --from-literal=type=git \\"
echo "    --from-literal=url=${REPO_URL} \\"
echo "    --from-literal=password=<TOKEN> \\"
echo "    --from-literal=username=<USERNAME>"
echo ""
echo "  kubectl label secret argocd-repo-k8ts -n argocd \\"
echo "    argocd.argoproj.io/secret-type=repository"
echo ""
read -r -p "Press Enter once the secret is created..." || true

echo "==> Applying root app"
kubectl apply -f "$(dirname "$0")/root-app.yaml"

echo "==> Done. ArgoCD will now sync the cluster from Git."
echo "    Run 'minikube tunnel' in a separate terminal to expose LoadBalancer services."
