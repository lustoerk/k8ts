
  1. minikube start --driver=qemu2 --memory=16384 --cpus=4 --disk-size=50g
  2. minikube addons enable metrics-server (optional, lightweight)
  3. helm repo add argo https://argoproj.github.io/argo-helm
  4. helm install argocd argo/argo-cd -n argocd --create-namespace \
       --set server.service.type=NodePort \
       --set configs.params."server\.insecure"=true
  5. kubectl wait --for=condition=available deployment/argocd-server -n argocd
  6. Create argocd-repo-creds Secret (GitHub PAT)
  7. kubectl apply -f root-app.yaml