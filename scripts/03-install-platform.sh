#!/usr/bin/env bash
# Installs ingress-nginx, ArgoCD, Kyverno. Verify chart/manifest versions against official docs.
source "$(dirname "$0")/common.sh"
ARGO_VERSION=${ARGO_VERSION:-v2.13.3}
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo add kyverno https://kyverno.github.io/kyverno >/dev/null
helm repo update >/dev/null

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace \
  --set controller.replicaCount=1 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.resources.requests.cpu=50m --set controller.resources.requests.memory=96Mi --wait

kubectl create ns argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGO_VERSION/manifests/install.yaml
kubectl -n argocd patch cm argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deploy argocd-server
kubectl -n argocd rollout status deploy argocd-server --timeout=300s

helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace --wait --timeout 10m
echo "Ingress IP:"; kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}{"\n"}'
echo "ArgoCD admin password:"; kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
