#!/usr/bin/env bash
# Usage: ./04-render-config.sh <github-owner/repo>   -> replaces __PLACEHOLDERS__ then you commit+push.
source "$(dirname "$0")/common.sh"
GH_REPO=${1:?usage: 04-render-config.sh owner/repo}
IP=$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
cd "$ROOT"
FILES=$(grep -rl '__[A-Z_]*__' k8s pipelines || true)
for f in $FILES; do
  sed -i \
    -e "s|__ACR_LOGIN_SERVER__|$(tfout acr_login_server)|g" -e "s|__ACR_NAME__|$(tfout acr_name)|g" \
    -e "s|__KV_NAME__|$(tfout key_vault_name)|g" -e "s|__TENANT_ID__|$(tfout tenant_id)|g" \
    -e "s|__AUTH_CLIENT_ID__|$(tfout auth_client_id)|g" -e "s|__GH_REPO_URL__|https://github.com/$GH_REPO.git|g" \
    -e "s|__GH_REPO__|$GH_REPO|g" -e "s|__INGRESS_IP__|$IP|g" -e "s|__TFSTATE_RG__|$TFSTATE_RG|g" \
    -e "s|__TFSTATE_SA__|$TFSTATE_SA|g" -e "s|__ADMIN_OID__|$TF_VAR_admin_object_id|g" "$f"
done
echo "Rendered. Now: git add -A && git commit -m 'render config' && git push"
