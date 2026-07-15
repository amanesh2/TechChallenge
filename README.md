# Quote of the Day on Azure

Production-style Azure implementation for a secure, highly available Quote of the Day web application delivered as Terraform-first infrastructure plus GitHub Actions CI/CD.

## Repository Structure

- `src/`: Node.js Express app and tests
- `terraform/`: bootstrap, platform, application layers and modules
- `db/seed/`: seed data and schema notes
- `scripts/`: bootstrap, seed, smoke test, and failover drill scripts
- `docs/`: architecture, addendum, runbooks, AI disclosure, OIDC guidance
- `.github/workflows/`: validation, plan, apply, deploy, security workflows

## Architecture

See:

- `docs/architecture.md`
- `docs/architecture-review.md`
- `docs/oidc-federation.md`
- `docs/architecture-diagram.md`

## Prerequisites

1. Terraform >= 1.8
2. Azure CLI >= 2.60
3. Node.js >= 22
4. GitHub repository configured with OIDC federation and environment protections

## Local Development

```bash
npm ci
npm test
npm run lint
npm start
```

The app requires:

- `SQL_SERVER_FQDN`
- `SQL_DATABASE_NAME`
- Optional: `APPLICATIONINSIGHTS_CONNECTION_STRING`

## Terraform Bootstrap

```bash
cd terraform/bootstrap
terraform init
terraform apply -var="storage_account_name=stqotdtfstate11"
```

## Terraform Platform (Demo)

```bash
cd terraform/platform
terraform init \
  -backend-config="resource_group_name=rg-qotd-bootstrap-eastus2" \
  -backend-config="storage_account_name=stqotdtfstate11" \
  -backend-config="container_name=platform-dev" \
  -backend-config="key=platform-dev.tfstate"
terraform apply -var-file=../environments/dev/platform.tfvars
```

## Terraform Application (Demo)

```bash
cd terraform/application
terraform init \
  -backend-config="resource_group_name=rg-qotd-bootstrap-eastus2" \
  -backend-config="storage_account_name=stqotdtfstate11" \
  -backend-config="container_name=application-dev" \
  -backend-config="key=application-dev.tfstate"
terraform apply \
  -var-file=../environments/dev/application.tfvars \
  -var="sql_admin_login=$SQL_ADMIN_LOGIN" \
  -var="sql_admin_password=$SQL_ADMIN_PASSWORD" \
  -var="entra_admin_login=$ENTRA_ADMIN_LOGIN" \
  -var="entra_admin_object_id=$ENTRA_ADMIN_OBJECT_ID"
```

## Database Seeding

After application deployment:

```bash
node scripts/seed-database.js
```

Use workload identity or managed identity context so no SQL password-based app authentication is required.

## Validation Commands

```bash
terraform fmt -recursive
terraform fmt -check -recursive

cd terraform/bootstrap && terraform init -backend=false && terraform validate && cd ../..
cd terraform/platform && terraform init -backend=false && terraform validate && cd ../..
cd terraform/application && terraform init -backend=false && terraform validate && cd ../..

tflint --init
tflint --recursive terraform

npm test
npm run lint
```

## CI/CD Workflows

- `terraform-validate.yml`: format, validate, tflint
- `terraform-plan.yml`: PR plan with OIDC and comment
- `terraform-apply-platform.yml`: platform apply for dev/prod
- `terraform-apply-application.yml`: application apply for dev/prod
- `app-ci.yml`: app lint/test/audit
- `app-deploy.yml`: deploy staging slot, smoke test, swap
- `codeql.yml`: code scanning

## Runbooks

- `docs/runbooks/disaster-recovery.md`
- `docs/runbooks/incident-response.md`

## Security Controls

- OIDC federation for Azure auth in workflows
- User-assigned managed identities for app and seeder
- Private endpoint connectivity for SQL and Key Vault
- Front Door WAF and origin restriction
- Centralized diagnostics to Log Analytics
- Build provenance attestation enabled

## Cost and Environment Strategy

Demo applies only the dev-like environment by default for cost control. Production tfvars exist to demonstrate target topology without forcing always-on production spend.
