# Security Policy

## Supported Versions

This project tracks security updates on the `main` branch.

## Reporting a Vulnerability

Email vulnerability reports to the repository owner and include:

- A concise description of the issue
- Reproduction steps
- Impact assessment
- Suggested remediation (if known)

Do not open public issues for undisclosed vulnerabilities.

## Security Baselines Implemented

- OIDC federation for GitHub Actions to Azure (no long-lived cloud secrets)
- Managed Identity for application and seeding workloads
- Private Endpoint access for Azure SQL and Key Vault
- Front Door + WAF edge ingress with App Service origin restriction
- Entra-authenticated database access path
- Dependabot and CodeQL enabled
- Build provenance attestation enabled in deployment workflow
