# OIDC Federation Configuration Guidance

This guide configures GitHub Actions to authenticate to Azure via Microsoft Entra workload identity federation with no long-lived cloud secrets.

## 1. Create Entra App Registration

1. Create an app registration for CI/CD identity, for example `app-qotd-github-actions`.
2. Record:
- Application (client) ID = 79276200-fa1d-4217-89a5-8c8254d40016
- Directory (tenant) ID = b5071aec-583e-4cdd-a4f5-2c6285f12b23

## 2. Create Federated Credentials

Add these federated credentials to the app registration:

1. `repo:amanesh2/TechChallenge:ref:refs/heads/main`
2. `repo:amanesh2/TechChallenge:environment:dev`
3. `repo:amanesh2/TechChallenge:environment:production`
4. `repo:amanesh2/TechChallenge:environment:plan`

Use:
- Issuer: `https://token.actions.githubusercontent.com`
- Audience: `api://AzureADTokenExchange`

Do not use broad wildcard subjects.

## 3. Assign Azure RBAC

Assign least privilege at resource-group scope:

1. `Contributor` on demo environment RGs for deployment credentials.
2. `Reader` on demo environment RGs for plan-only credentials.
3. `Storage Blob Data Contributor` on state containers used by Terraform backend.
4. `Website Contributor` scoped to App Service for app deployment jobs when you want narrower permissions than full RG `Contributor`.

## 4. Configure GitHub Repository Variables/Secrets

Repository Variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `TFSTATE_RG`
- `TFSTATE_STORAGE_ACCOUNT`
- `TFSTATE_PLATFORM_CONTAINER_DEV`
- `TFSTATE_APPLICATION_CONTAINER_DEV`
- `TFSTATE_PLATFORM_CONTAINER_PROD`
- `TFSTATE_APPLICATION_CONTAINER_PROD`
- `SQL_ADMIN_LOGIN`
- `ENTRA_ADMIN_LOGIN`
- `ENTRA_ADMIN_OBJECT_ID`
- `APP_SERVICE_NAME`
- `APP_RESOURCE_GROUP`

Repository Secrets:

- `SQL_ADMIN_PASSWORD`

## 5. GitHub Environment Controls

Create environments:

1. `plan` with no required reviewer.
2. `dev` with no required reviewer.
3. `production` with required reviewer approval.

## 6. Workflow Requirements

Each Azure-authenticating workflow must include:

- `permissions: id-token: write`
- `azure/login@v2` with `audience: api://AzureADTokenExchange`

Each production workflow should set:

- `environment: production`
- `concurrency` to prevent parallel applies.

## 7. Verification

1. Trigger plan workflow on an internal PR.
2. Confirm Azure login succeeds without any client secret.
3. Verify fork PRs do not execute privileged plan steps.
4. Trigger production workflow and verify environment approval gate is enforced.
