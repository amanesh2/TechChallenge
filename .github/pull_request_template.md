## Summary

Describe the change and why it is needed.

## Validation

- [ ] `terraform fmt -check -recursive`
- [ ] `terraform validate` run for `bootstrap`, `platform`, and `application`
- [ ] `tflint --recursive terraform`
- [ ] `npm test`
- [ ] `npm run lint`

## Security and Operations

- [ ] No plaintext credentials or tokens committed
- [ ] Managed Identity and least-privilege assumptions preserved
- [ ] Any architecture trade-offs documented in docs

## Deployment Impact

- [ ] Platform changes
- [ ] Application changes
- [ ] Database schema or seed changes