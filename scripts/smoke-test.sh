#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SMOKE_BASE_URL:-}" ]]; then
  echo "SMOKE_BASE_URL must be set"
  exit 1
fi

echo "Running smoke tests against ${SMOKE_BASE_URL}"

curl -fsS "${SMOKE_BASE_URL}/health" >/dev/null
#curl -fsS "${SMOKE_BASE_URL}/health/ready" >/dev/null

QUOTE_JSON="$(curl -fsS "${SMOKE_BASE_URL}/api/quote")"
if ! echo "${QUOTE_JSON}" | grep -q '"quote"'; then
  echo "Quote payload missing quote field"
  exit 1
fi

echo "Smoke tests completed successfully"