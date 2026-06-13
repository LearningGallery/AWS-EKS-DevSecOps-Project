# ADR-002: Module Architecture Strategy

## Status
Accepted

## Context
We needed to decide how to organise Terraform modules — whether to use a flat structure, hierarchical modules, or a monolithic configuration.

## Decision
Use a **flat module hierarchy** with a single root module orchestrating 6 independent child modules.

```
Root Module (Infra-Code_UAT/main.tf)
├── module.core_iam
├── module.core_vpc
├── module.ec2_infrastructure
├── module.core_ecr
└── module.core_eks
```

## Consequences

**Benefits:**
- Single `terraform apply` deploys everything
- Explicit dependencies visible in one file (`main.tf`)
- Each module independently reusable in other projects
- Simple mental model — no nested module traversal

**Trade-offs:**
- Root `main.tf` grows larger as infrastructure expands
- No module versioning (local modules only)
- All modules share one Terraform state

## Alternatives Considered

| Option | Reason Not Chosen |
|--------|------------------|
| Monolithic single file | No reusability, hard to maintain |
| Deeply nested modules | Complex dependency chains, hard to debug |
| Separate state per module | Multiple apply commands needed, complex data sharing |
| Terraform Registry modules | External dependency, less learning value |
