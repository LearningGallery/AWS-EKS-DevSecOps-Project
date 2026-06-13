# ADR-005: CSV-Driven Data Engine

## Status
Accepted

## Context
We needed an approach for managing infrastructure configuration that:
- Allows non-Terraform engineers to modify infrastructure
- Scales to many resources without code changes
- Provides a clear audit trail of infrastructure changes
- Keeps HCL code stable while configuration changes frequently

## Decision
Use a **CSV-driven data engine** where all infrastructure definitions live in CSV files and are parsed into Terraform maps via `csvdecode()` and `locals`.

```hcl
locals {
  raw_subnets = csvdecode(file("${path.module}/data/subnets.csv"))
  subnet_map  = { for r in local.raw_subnets : r.id => r }
}
```

## Consequences

**Benefits:**
- Infrastructure teams can use Excel/Google Sheets to manage config
- Adding a new subnet = adding one CSV row (no HCL editing)
- CSV files are diffable in Git (clear audit trail)
- Consistent structure enforced by CSV schema
- Enables bulk changes across many resources simultaneously

**Trade-offs:**
- Debugging CSV parsing errors can be cryptic
- No type validation (all CSV values are strings — must cast manually)
- Complex logic (conditionals, nested objects) harder to express in CSV
- CSV format less expressive than HCL for complex configurations

## Alternatives Considered

| Option | Reason Not Chosen |
|--------|------------------|
| Pure HCL variables | Requires HCL knowledge for every change |
| YAML data files | Less universally familiar than CSV/Excel |
| JSON data files | Harder to edit manually than CSV |
| Terraform Cloud Variables | External dependency, less portable |
