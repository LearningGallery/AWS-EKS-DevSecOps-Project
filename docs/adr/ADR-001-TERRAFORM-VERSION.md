# ADR-001: Terraform Version Selection

## Status
Accepted

## Context
We needed to select a Terraform version for this project that balances:
- Access to latest AWS provider features (EKS access entries, S3 native locking)
- Stability and production readiness
- Team familiarity

## Decision
Use **Terraform >= 1.12** with AWS provider `~> 5.0`.

Key features used from recent versions:
- `use_lockfile = true` (S3 native locking, Terraform 1.10+)
- `aws_eks_access_entry` resource (AWS provider 5.10+)
- `aws_eks_access_policy_association` resource (AWS provider 5.10+)

## Consequences

**Benefits:**
- Native S3 state locking eliminates DynamoDB dependency
- EKS access entries replace ConfigMap-based auth (more secure)
- Latest AWS provider features available

**Trade-offs:**
- Teams on older Terraform must upgrade
- `use_lockfile` not backward-compatible with Terraform < 1.10

## Alternatives Considered

| Option | Reason Not Chosen |
|--------|------------------|
| Terraform 1.5 | Missing `use_lockfile` support |
| OpenTofu | Team standardised on HashiCorp Terraform |
| Pulumi | Requires different language skills (TypeScript/Python) |
