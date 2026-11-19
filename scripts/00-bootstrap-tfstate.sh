#!/usr/bin/env bash
# Creates the Terraform remote-state storage (Azure AD auth only, versioned). ~$0.01/month.
source "$(dirname "$0")/common.sh"
LOC=${LOCATION:-centralindia}
RG=rg-tfstate-$PREFIX
SA=tfstate$RANDOM$RANDOM
az group create -n $RG -l $LOC -o none
az storage account create -n $SA -g $RG -l $LOC --sku Standard_LRS --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false -o none
az storage account blob-service-properties update --account-name $SA -g $RG --enable-versioning true -o none
SAID=$(az storage account show -n $SA -g $RG --query id -o tsv)
az role assignment create --assignee "$TF_VAR_admin_object_id" --role "Storage Blob Data Contributor" --scope $SAID -o none
echo "Waiting for RBAC to propagate..."
for i in $(seq 1 12); do
  az storage container create -n tfstate --account-name $SA --auth-mode login -o none 2>/dev/null && break || sleep 15
done
printf 'export TFSTATE_RG=%s\nexport TFSTATE_SA=%s\n' $RG $SA > "$ROOT/scripts/.tfstate.env"
echo "State storage ready: $SA"
