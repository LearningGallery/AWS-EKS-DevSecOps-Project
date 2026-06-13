# ADR-003: Remote State Backend Selection

## Status
Accepted

## Context
We needed a remote state backend that supports:
- Team collaboration (shared state)
- State locking (prevent concurrent applies)
- Encryption at rest
- Versioning for recovery
- Minimal additional infrastructure

## Decision
Use **AWS S3 with native state locking** (`use_lockfile = true`).

```hcl
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "core-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

## Consequences

**Benefits:**
- No DynamoDB table needed (saves ~$0/month on PAY_PER_REQUEST, but simplifies setup)
- S3 versioning provides automatic state history
- AES256 encryption at rest
- Already using AWS — no additional service dependency

**Trade-offs:**
- `use_lockfile` requires Terraform >= 1.10
- S3 native locking less battle-tested than DynamoDB locking
- Lock file left behind on crash requires manual cleanup

## Alternatives Considered

| Option | Reason Not Chosen |
|--------|------------------|
| S3 + DynamoDB | Still supported but native locking is simpler |
| Terraform Cloud | Requires account, added complexity for learning project |
| Local state | Not suitable for team use |
| HashiCorp Consul | Overkill for single-project use |
