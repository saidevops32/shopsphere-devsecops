#!/usr/bin/env bash
# Usage: ./01-terraform-apply.sh [plan|apply]   (default apply). Takes ~10-15 min.
source "$(dirname "$0")/common.sh"
ACTION=${1:-apply}
cd "$TF_DIR"
terraform init -input=false -backend-config="resource_group_name=$TFSTATE_RG" \
  -backend-config="storage_account_name=$TFSTATE_SA" -backend-config="container_name=tfstate" -backend-config="key=$ENVN.tfstate"
terraform fmt -recursive
terraform validate
if [ "$ACTION" = plan ]; then terraform plan -var-file=envs/$ENVN.tfvars; exit 0; fi
terraform apply -parallelism=1 -var-file=envs/$ENVN.tfvars
