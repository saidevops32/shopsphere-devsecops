#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
az aks start -g "$(tfout resource_group)" -n "$(tfout aks_name)"
