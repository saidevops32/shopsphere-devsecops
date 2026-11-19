# Sourced by other scripts (Azure Cloud Shell, bash)
set -euo pipefail
export PREFIX=${PREFIX:-shopsphere}
export ENVN=${ENVN:-dev}
export ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export TF_DIR="$ROOT/infra/terraform"
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TF_VAR_admin_object_id=$(az ad signed-in-user show --query id -o tsv)
[ -f "$ROOT/scripts/.tfstate.env" ] && source "$ROOT/scripts/.tfstate.env"
tfout() { (cd "$TF_DIR" && terraform output -raw "$1"); }
