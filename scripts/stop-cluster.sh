#!/usr/bin/env bash
# Stop compute billing between sessions (keeps state). Start again with start-cluster.sh
source "$(dirname "$0")/common.sh"
az aks stop -g "$(tfout resource_group)" -n "$(tfout aks_name)" --no-wait
echo "AKS stopping. LB/ACR/LAW/Key Vault still cost pennies; run teardown.sh for zero."
