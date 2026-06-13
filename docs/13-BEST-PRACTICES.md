# ✅ Best Practices

---

## 1. Terraform Configuration Best Practices

### Use `for_each` Over `count` for Named Resources

```hcl
# ✅ Good — stable resource addressing
resource "aws_ecr_repository" "registry" {
  for_each = local.repos
  name     = each.key
}
# Address: aws_ecr_repository.registry["frontend"]
# Deleting one entry only removes that resource

# ❌ Avoid — index-based addressing is fragile
resource "aws_ecr_repository" "registry" {
  count = length(var.repos)
  name  = var.repos[count.index]
}
# Address: aws_ecr_repository.registry[0]
# Deleting entry [0] causes ALL subsequent resources to shift and recreate
```

### Pin Provider Versions

```hcl
# ✅ Good — pin with pessimistic constraint operator
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # Allows 5.x but not 6.x
    }
  }
}

# ❌ Avoid — unpinned versions can break on provider updates
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}
```

### Use `locals` to Avoid Repetition

```hcl
# ✅ Good — compute once, reference many times
locals {
  base = "${var.project_code}-${var.environment}-${var.network_zone}"
}
resource "aws_vpc" "vpc" {
  tags = { Name = "vp-${local.base}-01" }
}
resource "aws_subnet" "subnets" {
  tags = { Name = "sn-${local.base}-${each.key}" }
}
```

### Always Use Remote State in Teams

```hcl
# ✅ Good — remote state prevents conflicts
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

---

## 2. Module Design Principles

### Single Responsibility

```
✅ Each module does ONE thing:
  modules/vpc  → networking only
  modules/eks  → Kubernetes cluster only
  modules/iam  → identity only

❌ Avoid monolithic modules that do everything
```

### Explicit Dependencies

```hcl
# ✅ Good — explicit dependency via output reference
module "ec2" {
  subnet_ids = [module.vpc.subnet_ids["web_az1"]]
  # Terraform knows ec2 depends on vpc automatically
}

# ❌ Avoid — implicit dependencies that Terraform can't track
module "ec2" {
  subnet_ids = ["subnet-hardcoded-id"]
}
```

### Always Provide Outputs

```hcl
# ✅ Every module should expose useful outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}
```

---

## 3. CSV Data Engine Best Practices

### Use Consistent Key Naming

```csv
# ✅ Good — descriptive, consistent keys
id,vpc_id,cidr_block,az,is_public,role
web_az1,core,10.0.1.0/24,ap-southeast-1a,true,web
eks_az1,core,10.0.10.0/24,ap-southeast-1a,false,eks

# ❌ Avoid — cryptic or inconsistent keys
subnet1,core,10.0.1.0/24,ap-southeast-1a,true,web
s2,core,10.0.10.0/24,ap-southeast-1a,false,eks
```

### Use Semicolons for Lists Within CSV Fields

```csv
# ✅ Good — semicolon-separated list in a field
subnet_ids,sg_ids
web_az1;web_az2,sg-web;sg-app

# Then split in Terraform:
subnet_ids = split(";", each.value.subnet_ids)
```

### Validate Boolean Fields

```hcl
# ✅ Always explicitly convert booleans from CSV
is_public = tobool(r.is_public)  # "true"/"false" → bool
encrypted = tobool(r.vol_encrypt)
```

---

## 4. Naming Conventions

### Resource Naming Pattern

```
<type_prefix>-<project>-<environment>-<zone>-<role>-<sequence>

Examples:
vp-cis-uat-ia-01          VPC
sn-cis-uat-ia-web-1a-01   Subnet (includes AZ)
sg-cis-uat-ia-web-01      Security Group
vm-cis-uat-ie-tvm-01      EC2 Instance
rl-cis-uat-eks-master     IAM Role
st-cis-uat-tfstate-123    S3 Bucket (account ID suffix)
```

### CSV Key Naming Pattern

```
<role>_<az_suffix>

Examples:
web_az1    Public subnet in AZ1
web_az2    Public subnet in AZ2
eks_az1    EKS subnet in AZ1
eks_az2    EKS subnet in AZ2
```

---

## 5. Security Best Practices Checklist

```
Terraform Code:
  ✅ Never hardcode credentials
  ✅ Never commit .tfstate to Git
  ✅ Never commit .tfvars with secrets to Git
  ✅ Use sensitive = true for sensitive outputs
  ✅ Pin provider versions

AWS Resources:
  ✅ Enable encryption at rest for all storage
  ✅ Block all public S3 access
  ✅ Enforce IMDSv2 on all EC2 instances
  ✅ Use IAM roles, never IAM users for applications
  ✅ Apply least-privilege IAM policies

Containers:
  ✅ Never run as root
  ✅ Set readOnlyRootFilesystem: true
  ✅ Drop all Linux capabilities
  ✅ Set resource requests and limits
  ✅ Implement health probes
  ✅ Use immutable image tags
```

---

## 6. Testing Strategy

```bash
# Level 1: Syntax validation
terraform validate
terraform fmt -check -recursive

# Level 2: Security scanning
trivy fs --scanners misconfig --severity HIGH,CRITICAL .
checkov -d . --framework terraform

# Level 3: Dry run
terraform plan -detailed-exitcode
# Exit code 0 = no changes
# Exit code 1 = error
# Exit code 2 = changes present

# Level 4: Integration testing (post-apply)
kubectl get nodes       # Nodes ready
kubectl get pods -A     # All pods running
aws eks describe-cluster --name cis-uat-eks_main  # Cluster active
```

---

## 7. Code Review Guidelines

Before merging any Terraform changes:

```
Network changes (sg_rules.csv, nacl_rules.csv):
  [ ] No 0.0.0.0/0 ingress for administrative ports (22, 3389, 8080)
  [ ] Each rule has a meaningful description
  [ ] Egress rules are minimal (only what's needed)

IAM changes (iam_roles.csv):
  [ ] No AdministratorAccess in production
  [ ] Trust relationship is specific (not *.amazonaws.com)
  [ ] Custom policies follow least-privilege

EKS changes (eks_clusters.csv, eks_node_groups.csv):
  [ ] K8s version is supported and not end-of-life
  [ ] Node count is appropriate for workload
  [ ] Disk size is sufficient

General:
  [ ] terraform plan reviewed and understood
  [ ] No accidental resource deletions
  [ ] Naming conventions followed
  [ ] Tags applied to all resources
```