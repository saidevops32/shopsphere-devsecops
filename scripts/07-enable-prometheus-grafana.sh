#!/usr/bin/env bash
# OPTIONAL (cost): Managed Prometheus + Managed Grafana. Run late, delete after the lab (teardown handles it via RG delete).
source "$(dirname "$0")/common.sh"
RG=$(tfout resource_group); AKS=$(tfout aks_name); LOC=${LOCATION:-centralindia}
az extension add --name amg --yes -o none
G=graf-$PREFIX-$ENVN-$RANDOM
az grafana create -n $G -g $RG -l $LOC -o none
az aks update -g $RG -n $AKS --enable-azure-monitor-metrics --grafana-resource-id "$(az grafana show -n $G -g $RG --query id -o tsv)" -o none
az role assignment create --assignee "$TF_VAR_admin_object_id" --role "Grafana Admin" --scope "$(az grafana show -n $G -g $RG --query id -o tsv)" -o none
az grafana show -n $G -g $RG --query properties.endpoint -o tsv
