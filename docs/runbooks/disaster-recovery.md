# Disaster Recovery Runbook

## Scope

Single-region deployment with region-restore DR using Terraform and Azure SQL backups.

## Objectives

- Target RPO: <= 15 minutes
- Target RTO: ~1 hour

## Preconditions

- Access to Azure subscription
- Terraform backend available
- Latest repository main branch
- SQL backup retention still valid

## Step 1: Select Recovery Region

Choose approved paired region and set deployment variables accordingly.

## Step 2: Restore SQL Database via PITR

```bash
az sql db restore \
  --dest-name sqldb-qotd-dr-eus2 \
  --edition GeneralPurpose \
  --capacity 2 \
  --resource-group "$DR_RESOURCE_GROUP" \
  --server "$DR_SQL_SERVER" \
  --name "$SOURCE_DATABASE_NAME" \
  --time "$UTC_RESTORE_POINT"
```

## Step 3: Rebuild Platform and Application

```bash
cd terraform/platform
terraform init -backend-config=... 
terraform apply -var-file=../environments/prod/platform.tfvars

cd ../application
terraform init -backend-config=...
terraform apply \
  -var-file=../environments/prod/application.tfvars \
  -var="sql_admin_login=$SQL_ADMIN_LOGIN" \
  -var="sql_admin_password=$SQL_ADMIN_PASSWORD" \
  -var="entra_admin_login=$ENTRA_ADMIN_LOGIN" \
  -var="entra_admin_object_id=$ENTRA_ADMIN_OBJECT_ID"
```

## Step 4: Repoint Front Door Routing

Update Front Door origin in the application layer to restored region App Service hostname and apply.

## Step 5: Validate Recovery

1. `GET /health` returns 200.
2. `GET /health/ready` returns 200.
3. `GET /api/quote` returns quote payload.
4. Verify App Insights dependency calls to SQL are successful.

## Step 6: Record Incident Timeline

Capture:

1. Outage start time.
2. Recovery start time.
3. Recovery complete time.
4. Effective RTO and RPO observed.

## Last Drill Record

- Drill execution date: 2026-07-10
- Recovery region: eastus2
- Observed RTO: 42 minutes
- Observed RPO: <= 10 minutes
