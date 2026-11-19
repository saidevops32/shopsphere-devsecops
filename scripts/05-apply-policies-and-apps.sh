#!/usr/bin/env bash
# Usage: ./05-apply-policies-and-apps.sh [dev|qa|prod ...]   (default: dev)
source "$(dirname "$0")/common.sh"
kubectl apply -f "$ROOT/k8s/policies/kyverno/"
for e in ${@:-dev}; do kubectl apply -f "$ROOT/k8s/gitops/app-$e.yaml"; done
kubectl -n argocd get applications
