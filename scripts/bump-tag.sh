#!/usr/bin/env bash
# Usage: bump-tag.sh <values-file> <service> <tag>   (needs env GH_PAT, GH_REPO=owner/repo; yq present on MS-hosted agents)
set -euo pipefail
FILE=$1; SVC=$2; TAG=$3
git config user.email "pipeline@shopsphere.local"
git config user.name "azure-pipelines"
git remote set-url origin "https://x-access-token:${GH_PAT}@github.com/${GH_REPO}.git"
for i in 1 2 3 4 5; do
  git fetch origin main
  git checkout -B main origin/main
  yq -i ".services[\"${SVC}\"].tag = \"${TAG}\"" "$FILE"
  git add "$FILE"
  git commit -m "gitops: ${SVC} -> ${TAG} in $(basename "$FILE") [skip ci]" || exit 0
  if git push origin HEAD:main; then exit 0; fi
  echo "push raced with another pipeline, retry $i"; sleep $((i*3))
done
exit 1
