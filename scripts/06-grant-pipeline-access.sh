#!/usr/bin/env bash
# Usage: ./06-grant-pipeline-access.sh <service-connection-app-client-id>
# Gives the Azure DevOps service connection identity ONLY what CI needs (AcrPush; optional signing/infra roles).
source "$(dirname "$0")/common.sh"
SP=${1:?usage: 06-grant-pipeline-access.sh <client-id>}
az role assignment create --assignee "$SP" --role AcrPush --scope "$(tfout acr_id)" -o none
echo "AcrPush granted."
echo "Optional (cosign signing):  az role assignment create --assignee $SP --role 'Key Vault Crypto User' --scope \$(az keyvault show -n $(tfout key_vault_name) --query id -o tsv)"
echo "Optional (infra pipeline apply): Contributor + User Access Administrator on the RG, Storage Blob Data Contributor on tfstate"
