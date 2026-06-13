# ⚠️ Known Issues & Limitations

---

## 1. Current Limitations

### Issue 1: No NAT Gateway for Private Subnets

**Status:** Known limitation  
**Severity:** Medium  
**Impact:** EKS worker nodes in private subnets (`eks_az1`, `eks_az2`) currently use public EKS endpoint for ECR pulls, which requires outbound internet access.

**Current Workaround:**
```
EKS nodes are currently deployed to public subnets (web_az1, web_az2) 
via eks_clusters.csv:
subnet_ids = web_az1;web_az2
```

**Proper Fix (Roadmap):**
```hcl
# Add NAT Gateway resource
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnets["web_az1"].id
}

# Add route to route_rules.csv:
# core,eks,0.0.0.0/0,nat
```

---

### Issue 2: Root Outputs Are Commented Out

**Status:** Known — intentional during development  
**Severity:** Low  
**Impact:** `terraform output` shows no values

**Workaround:**
```bash
# Uncomment output.tf to activate outputs
# Then run:
terraform apply -refresh-only
terraform output
```

**Fix:** Remove `/* ... */` comment blocks from `output.tf`

---

### Issue 3: Security Groups Allow 0.0.0.0/0 on Administrative Ports

**Status:** Known — acceptable for UAT/learning  
**Severity:** High (in production context)  
**Impact:** Jenkins (8080), SonarQube (9000), SSH (22) are exposed to the internet

**Workaround for production:**
```csv
# data/sg_rules.csv — replace 0.0.0.0/0 with your IP:
core,web,ingress,22,22,tcp,cidr,YOUR_IP/32,Allow SSH from office
core,web,ingress,8080,8080,tcp,cidr,YOUR_IP/32,Allow Jenkins from office
core,web,ingress,9000,9000,tcp,cidr,YOUR_IP/32,Allow SonarQube from office
```

---

### Issue 4: Bootstrap State Is Local

**Status:** Known — by design  
**Severity:** Low  
**Impact:** `terraform-bootstrap/terraform.tfstate` is stored locally

**Explanation:**
The bootstrap cannot use a remote backend because it creates the remote backend. Local state for bootstrap is a standard pattern.

**Mitigation:**
```bash
# The bootstrap tfstate file is committed to Git (intentionally)
# It is safe to commit because it only contains S3 and DynamoDB resource info
# No sensitive values in bootstrap state
```

---

### Issue 5: `cluster_security_group_ids` Is Empty List

**Status:** Known — deliberate workaround  
**Severity:** Low  
**Impact:** No additional security groups attached to EKS control plane

**In main.tf:**
```hcl
# This is intentionally empty to avoid circular dependency:
# VPC SG → EKS cluster → EKS managed SG → VPC SG rules
cluster_security_group_ids = []
```

**Explanation:**
EKS creates its own managed security group. The `eks_default` rules in `sg_rules.csv` are applied directly to the EKS managed SG (in the EKS module), not via `cluster_security_group_ids`, to prevent a resource cycle.

---

### Issue 6: Jenkinsfiles Use Hardcoded AWS Account ID

**Status:** Known  
**Severity:** Low  
**Impact:** Jenkinsfiles must be updated when used in a different AWS account

**Affected files:**
- All files in `Apps-Code_UAT/jenkinsfiles/`
- All files reference: `AWS_ACCOUNT_ID = "485950501937"`

**Workaround:**
```groovy
// Replace hardcoded ID with Jenkins credential:
environment {
  AWS_ACCOUNT_ID = credentials('aws-account-id')  // Store in Jenkins
}
```

---

### Issue 7: EKS Nodes Deployed in Public Subnets

**Status:** Known — development convenience  
**Severity:** Medium (production concern)  
**Impact:** EKS worker nodes have public IP addresses

**From eks_clusters.csv:**
```csv
subnet_ids = web_az1;web_az2  # These are PUBLIC subnets
```

**Production fix:**
```csv
# Use private EKS subnets instead:
subnet_ids = eks_az1;eks_az2  # These are PRIVATE subnets
# NOTE: Requires NAT Gateway first (Issue 1)
```

---

### Issue 8: PostgreSQL Init May Fail on Re-run

**Status:** Known  
**Severity:** Low  
**Impact:** Bootstrap script may fail if EC2 instance is stopped/started

**In `updated_install-tools.sh`:**
```bash
# This check prevents re-initialization:
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    postgresql-setup --initdb
fi
```

The script handles this gracefully with an existence check.

---

### Issue 9: `s3_buckets.csv` Is Empty

**Status:** Known  
**Severity:** Informational  
**Impact:** S3 module is defined but no buckets are created via CSV

**Explanation:**
The S3 module (`modules/s3`) exists but is not called in `main.tf`. The only S3 bucket created is the Terraform state bucket (via bootstrap).

---

### Issue 10: `ecr_repos.csv` Is Unused

**Status:** Known  
**Severity:** Informational  
**Impact:** Legacy file — not used by main.tf

**Explanation:**
`data/ecr_repos.csv` is a legacy file. The active ECR configuration file is `data/ecr_repositories.csv`. The legacy file can be deleted safely.

```bash
# Safe to remove:
rm Project/LearningGallery/Infra-Code_UAT/data/ecr_repos.csv
```

---

## 2. Terraform Version Compatibility

| Terraform Version | Status | Notes |
|------------------|--------|-------|
| `>= 1.12` | ✅ Tested | `use_lockfile = true` requires 1.10+ |
| `1.10 - 1.11` | ⚠️ Partial | S3 native locking may behave differently |
| `< 1.10` | ❌ Unsupported | `use_lockfile` not available — use `dynamodb_table` instead |

**For Terraform < 1.10, replace `backend.tf`:**
```hcl
terraform {
  backend "s3" {
    bucket         = "st-cis-uat-tfstate-485950501937"
    key            = "core-infra/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "tb-cis-uat-tflocks"  # Use DynamoDB locking instead
    encrypt        = true
  }
}
```

---

## 3. Known Provider Quirks

### AWS Provider ~> 5.0

```hcl
# aws_eks_access_entry requires provider >= 5.10
resource "aws_eks_access_entry" "ec2_profile_access" { ... }

# aws_eks_access_policy_association requires provider >= 5.10
resource "aws_eks_access_policy_association" "ec2_profile_admin" { ... }
```

### TLS Provider

```hcl
# Required for OIDC thumbprint calculation
# Automatically fetched but must be available:
data "tls_certificate" "eks" {
  url = each.value.oidc_issuer_url
  # Requires internet access during terraform plan/apply
}
```
