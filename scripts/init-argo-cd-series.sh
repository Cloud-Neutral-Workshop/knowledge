#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="content/02-iac-devops/argo-cd"

FILES=(
  "README.md"
  "00-why-gitops-and-argo-cd.md"
  "01-bootstrap-argocd.md"
  "02-repo-and-access-model.md"
  "03-application-and-sync-model.md"
  "04-helm-and-helmfile.md"
  "05-ci-and-artifact-boundary.md"
  "06-multi-env-and-appset.md"
  "07-sync-strategy-and-rollout.md"
  "08-security-and-blast-radius.md"
  "09-observability-and-operations.md"
  "99-reference-architecture.md"
)

echo "→ Initializing Argo CD series directory: ${BASE_DIR}"

mkdir -p "${BASE_DIR}"

for file in "${FILES[@]}"; do
  path="${BASE_DIR}/${file}"
  if [[ -f "${path}" ]]; then
    echo "  = Skipped (exists): ${file}"
  else
    touch "${path}"
    echo "  + Created: ${file}"
  fi
done

echo "✓ Argo CD series skeleton initialized."
