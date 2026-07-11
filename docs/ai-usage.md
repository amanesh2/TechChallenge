# AI Usage Disclosure

## Summary

This repository was delivered with AI-assisted drafting and human validation. AI was used to accelerate scaffolding and repetitive authoring while all architecture, security, and deployment decisions remained engineer-reviewed.

## Where AI Was Used

1. Architecture drafting and trade-off framing in docs.
2. Terraform module scaffolding for repetitive resource blocks.
3. GitHub Actions workflow authoring for OIDC and deployment orchestration.
4. Node.js route/test boilerplate and script skeletons.
5. Documentation structure and runbook drafting.

## Hallucinations Caught and Corrected

1. Incorrect/legacy Terraform arguments from older AzureRM versions were removed during validate/fmt passes.
2. Action workflow composition constraints were corrected so reusable and direct workflows were not mixed incorrectly.
3. SQL data-plane assumptions were moved to explicit seeding and runbook guidance instead of pretending Terraform can natively grant database roles.

## Review Workflow

1. Generate draft with AI.
2. Validate against architecture constraints.
3. Run `terraform fmt`, `terraform validate`, `tflint`, tests, and lint.
4. Fix schema/argument mismatches.
5. Re-run checks and finalize.

## Accountability Statement

AI output is treated as a first draft. All final artifacts in this repository are human-reviewed and intended for production-style quality within the interview scope.