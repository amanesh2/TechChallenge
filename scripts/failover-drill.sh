#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${AZ_SQL_RESOURCE_GROUP:-}" || -z "${AZ_SQL_SERVER:-}" || -z "${AZ_SQL_DATABASE:-}" ]]; then
  echo "Set AZ_SQL_RESOURCE_GROUP, AZ_SQL_SERVER, and AZ_SQL_DATABASE before running."
  exit 1
fi

echo "Starting Azure SQL failover drill for ${AZ_SQL_SERVER}/${AZ_SQL_DATABASE}"

az sql db failover \
  --resource-group "${AZ_SQL_RESOURCE_GROUP}" \
  --server "${AZ_SQL_SERVER}" \
  --name "${AZ_SQL_DATABASE}"

echo "Failover drill completed. Verify app dependency retry telemetry in Application Insights."