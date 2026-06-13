# 🌍 Multi-Environment Deployment Pattern

This example shows how to deploy to multiple environments (dev, uat, prod) using this project structure.

---

## Recommended Directory Structure

```
Project/
└── LearningGallery/
    ├── Infra-Code_DEV/
    │   ├── main.tf        # Same as UAT (symlink or copy)
    │   ├── provider.tf
    │   ├── backend.tf     # Different key: dev-infra/terraform.tfstate
    │   ├── variables.tf
    │   └── data/
    │       ├── vpcs.csv           # env = dev, CIDR = 10.0.0.0/16
    │       ├── subnets.csv        # Smaller subnets
    │       ├── eks_clusters.csv   # Smaller K8s version or disabled
    │       └── eks_node_groups.csv # min=1, max=3, desired=1, t3.medium
    │
    ├── Infra-Code_UAT/    # Current (this project)
    │   └── data/
    │       ├── vpcs.csv           # env = uat, CIDR = 10.0.0.0/16
    │       └── eks_node_groups.csv # min=2, max=10, desired=3, t3.large
    │
    └── Infra-Code_PROD/
        ├── backend.tf     # key: prod-infra/terraform.tfstate
        └── data/
            ├── vpcs.csv           # env = prd, CIDR = 10.1.0.0/16
            ├── subnets.csv        # More subnets, smaller CIDRs
            ├── sg_rules.csv       # No 0.0.0.0/0 rules
            └── eks_node_groups.csv # min=3, max=20, desired=5, t3.xlarge
```

---

## Environment Comparison

| Setting | DEV | UAT | PROD |
|---------|-----|-----|------|
| VPC CIDR | `10.0.0.0/16` | `10.0.0.0/16` | `10.1.0.0/16` |
| Node type | `t3.medium` | `t3.large` | `t3.xlarge` |
| Node desired | 1 | 3 | 5 |
| Node max | 3 | 10 | 20 |
| K8s version | `1.31` | `1.31` | `1.31` |
| SSH source | `0.0.0.0/0` | `0.0.0.0/0` | `10.0.0.0/8` |
| State key | `dev-infra/` | `core-infra/` | `prod-infra/` |

---

## Shared State Bucket

All environments share one S3 state bucket but use different state keys:

```hcl
# DEV backend.tf
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "dev-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}

# UAT backend.tf (current)
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "core-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}

# PROD backend.tf
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "prod-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

---

## Deploying to a Specific Environment

```bash
# Deploy DEV
cd Project/LearningGallery/Infra-Code_DEV
terraform init && terraform apply

# Deploy UAT
cd Project/LearningGallery/Infra-Code_UAT
terraform init && terraform apply

# Deploy PROD
cd Project/LearningGallery/Infra-Code_PROD
terraform init && terraform apply
```
