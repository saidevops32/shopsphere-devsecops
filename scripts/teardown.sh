#!/usr/bin/env bash
# Destroys EVERYTHING billable. Run when finished. Pass --include-state to also remove tfstate storage.
source "$(dirname "$0")/common.sh"
read -r -p "Destroy all ShopSphere Azure resources for env '$ENVN'? type yes: " a; [ "$a" = yes ] || exit 1
# Remove ingress LB first so Azure cleans public IP/LB
kubectl delete ns shopsphere-dev shopsphere-qa shopsphere-prod ingress-nginx --ignore-not-found --wait=false || true
cd "$TF_DIR"
terraform init -input=false -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$TFSTATE_SA" -backend-config="container_name=tfstate" -backend-config="key=$ENVN.tfstate"
# Grafana/Prometheus (created by script 07) live inside the RG; delete leftovers first
az resource list -g "rg-$PREFIX-$ENVN-cin-01" --resource-type Microsoft.Dashboard/grafana --query "[].id" -o tsv | xargs -r -n1 az resource delete --ids || true
terraform destroy -var-file=envs/$ENVN.tfvars
az group delete -n "MC_rg-$PREFIX-$ENVN-cin-01_aks-$PREFIX-$ENVN-cin-01_$(az group show -n rg-$PREFIX-$ENVN-cin-01 --query location -o tsv)" --yes --no-wait 2>/dev/null || true
if [ "${1:-}" = "--include-state" ]; then az group delete -n "$TFSTATE_RG" --yes --no-wait; fi
echo "Verify in Portal > Resource groups that nothing named *shopsphere* remains. Also purge soft-deleted Key Vaults if needed."
