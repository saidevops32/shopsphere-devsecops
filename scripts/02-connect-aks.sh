#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
RG=$(tfout resource_group); AKS=$(tfout aks_name)
az aks get-credentials -g $RG -n $AKS --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
kubectl get nodes
