#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}/terraform/bootstrap"

terraform init
terraform apply -auto-approve

echo "Bootstrap complete. Configure backend settings in terraform/platform and terraform/application via -backend-config values."