#!/usr/bin/env bash
# Helper: load .env (if present), substitute variables in custom-resources.yaml and apply
set -euo pipefail

if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst not found; please install gettext (provides envsubst)"
  exit 1
fi

# Substitute and apply
envsubst < custom-resources.yaml | kubectl apply -f -

echo "Applied custom-resources with substituted variables."
