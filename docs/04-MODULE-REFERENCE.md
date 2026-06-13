# 📖 Module Reference

---

## Module 1: VPC (`modules/vpc`)

### Purpose
Deploys a complete AWS networking stack including VPC, subnets, internet gateway, route tables, security groups, NACLs, and routing rules. All resources are dynamically created from input maps derived from CSV files.

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_vpc` | 1 | Core VPC |
| `aws_internet_gateway` | 0 or 1 | Created only if public subnets exist |
| `aws_subnet` | Dynamic | One per entry in `subnets` map |
| `aws_route_table` | Dynamic | 1 public + 1 per unique private role |
| `aws_route_table_association` | Dynamic | One per subnet |
| `aws_route` | Dynamic | One per entry in `route_rules` |
| `aws_security_group` | Dynamic | One per unique role |
| `aws_security_group_rule` | Dynamic | One per entry in `sg_rules` (excluding eks_default) |
| `aws_network_acl` | Dynamic | One per unique subnet role |
| `aws_network_acl_rule` | Dynamic | One per entry in `nacl_rules` |

### Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project_code` | `string` | ✅ | — | 3-char project code (e.g., `cis`) |
| `environment` | `string` | ✅ | — | Environment tag (e.g., `uat`) |
| `network_zone` | `string` | ✅ | — | 2-char zone code (e.g., `ia`) |
| `vpc_cidr` | `string` | ✅ | — | VPC CIDR block (e.g., `10.0.0.0/16`) |
| `subnets` | `map(object)` | ✅ | — | Subnet definitions from CSV |
| `sg_rules` | `list(map)` | ❌ | `[]` | Security group rules from CSV |
| `nacl_rules` | `list(map)` | ❌ | `[]` | NACL rules from CSV |
| `route_rules` | `list(map)` | ❌ | `[]` | Route rules from CSV |
| `transit_gateway_id` | `string` | ❌ | `null` | TGW ID for attachment |
| `common_tags` | `map(string)` | ❌ | `{}` | Common resource tags |

### Subnet Object Structure

```hcl
subnets = {
  "web_az1" = {
    cidr_block = "10.0.1.0/24"
    az         = "ap-southeast-1a"
    is_public  = true
    role       = "web"
  }
}
```

### Outputs

| Output | Type | Description | Example |
|--------|------|-------------|---------|
| `vpc_id` | `string` | VPC ID | `vpc-0a1b2c3d4e5f` |
| `vpc_cidr_block` | `string` | VPC CIDR | `10.0.0.0/16` |
| `subnet_ids` | `map(string)` | Map of subnet IDs by CSV key | `{ "web_az1" = "subnet-XXXX" }` |
| `sg_ids` | `map(string)` | Map of SG IDs prefixed with `sg-` | `{ "sg-web" = "sg-XXXX" }` |
| `public_route_table_id` | `string` | Public RT ID or null | `rtb-XXXX` |
| `private_route_table_ids` | `map(string)` | Private RT IDs by role | `{ "eks" = "rtb-XXXX" }` |
| `nacl_ids` | `map(string)` | NACL IDs by role | `{ "web" = "acl-XXXX" }` |
| `internet_gateway_id` | `string` | IGW ID or null | `igw-XXXX` |

### Example Usage

```hcl
module "core_vpc" {
  source       = "../../../modules/vpc"
  for_each     = local.vpc_map

  project_code = each.value.project
  environment  = each.value.env
  network_zone = each.value.network_zone
  vpc_cidr     = each.value.cidr_block

  subnets    = { for k, v in local.subnet_map : k => v if v.vpc_id == each.key }
  sg_rules   = [ for r in local.raw_sg : r if r.vpc_id == each.key ]
  nacl_rules = [ for r in local.raw_nacl : r if r.vpc_id == each.key ]
  route_rules = [ for r in local.raw_route : r if r.vpc_id == each.key ]
}
```

### Important Design Notes

- **eks_default SG rules** — Rules with `sg_role = "eks_default"` are intentionally **excluded** from the VPC module to prevent circular dependency. They are applied directly to the EKS cluster's managed security group in the EKS module.
- **Dynamic route tables** — One public RT is created (shared across all public subnets). One private RT is created per unique subnet role.
- **NACL assignment** — NACLs are assigned per role, grouping all same-role subnets under one NACL.

---

## Module 2: IAM (`modules/iam`)

### Purpose
Creates IAM roles, attaches managed and custom policies, and optionally creates instance profiles. Designed to be driven by a map of role configurations (from CSV).

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_iam_role` | Dynamic | One per role in input map |
| `aws_iam_policy` | Dynamic | One per role with non-empty `custom_policy_file` |
| `aws_iam_role_policy_attachment` | Dynamic | Multiple per role (managed + custom) |
| `aws_iam_instance_profile` | Dynamic | One per role with `create_instance_profile = true` |

### Input Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `roles` | `map(any)` | ✅ | Map of role configurations from CSV |

### Role Object Structure (from iam_roles.csv)

```hcl
roles = {
  "eks-master" = {
    project                = "cis"
    env                    = "uat"
    trusted_service        = "eks.amazonaws.com"
    managed_policies       = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy;arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    custom_policy_file     = ""
    create_instance_profile = false
  }
}
```

### How Policies Are Attached

The module uses a **flatten pattern** to handle semicolon-separated policy lists:

```hcl
# Input: "arn:aws:iam::aws:policy/PolicyA;arn:aws:iam::aws:policy/PolicyB"
# Result: Two separate policy attachment resources
managed_policy_attachments = flatten([
  for role_key, role_val in var.roles : [
    for policy in split(";", role_val.managed_policies) : {
      role_key = role_key
      policy   = policy
    } if policy != ""
  ]
])
```

### Outputs

| Output | Type | Description | Example |
|--------|------|-------------|---------|
| `role_arns` | `map(string)` | Map of role ARNs by role_id | `{ "eks-master" = "arn:aws:iam::485950501937:role/rl-cis-uat-eks-master" }` |
| `instance_profile_names` | `map(string)` | Map of profile names by role_id | `{ "ec2-profile" = "ip-cis-uat-ec2-profile" }` |

### Example Usage

```hcl
module "core_iam" {
  source = "../../../modules/iam"
  roles  = local.iam_map
}

# Reference outputs in other modules:
cluster_role_arn = module.core_iam.role_arns["eks-master"]
node_role_arn    = module.core_iam.role_arns["eks-node"]
iam_instance_profile = module.core_iam.instance_profile_names["ec2-profile"]
```

---

## Module 3: EC2 (`modules/ec2`)

### Purpose
Provisions one or more EC2 instances with consistent naming, encrypted EBS volumes, IMDSv2 enforcement, optional user data scripts, and optional IAM instance profiles.

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_instance` | `var.instance_count` | EC2 instances with IMDSv2 |

### Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project_code` | `string` | ✅ | — | Project code for naming |
| `environment` | `string` | ✅ | — | Environment for naming |
| `network_zone` | `string` | ✅ | — | Network zone for naming |
| `role` | `string` | ✅ | — | Server role for naming |
| `instance_count` | `number` | ❌ | `1` | Number of instances |
| `instance_types` | `list(string)` | ✅ | — | List of instance types |
| `ami_id` | `string` | ✅ | — | AMI ID |
| `subnet_ids` | `list(string)` | ✅ | — | Subnet IDs (from VPC module) |
| `vpc_security_group_ids` | `list(string)` | ❌ | `[]` | SG IDs (from VPC module) |
| `iam_instance_profile` | `string` | ❌ | `null` | IAM profile name |
| `root_volume_size` | `number` | ❌ | `20` | EBS size in GB |
| `root_volume_type` | `string` | ❌ | `gp3` | EBS type |
| `encrypted` | `bool` | ❌ | `true` | EBS encryption |
| `user_data` | `string` | ❌ | `null` | Bootstrap script content |
| `associate_public_ip_address` | `bool` | ❌ | `false` | Public IP assignment |
| `key_name` | `string` | ❌ | `null` | SSH key pair name |
| `common_tags` | `map(string)` | ❌ | `{}` | Common tags |

### Security Features

```hcl
# IMDSv2 enforced — prevents SSRF attacks on EC2 metadata
metadata_options {
  http_endpoint = "enabled"
  http_tokens   = "required"  # Forces token-based access
}

# Encrypted root volume
root_block_device {
  encrypted = var.encrypted  # true by default
}

# AMI changes ignored after deployment (prevents drift)
lifecycle {
  ignore_changes = [ami]
}
```

### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `instance_ids` | `list(string)` | EC2 instance IDs |
| `private_ips` | `list(string)` | Private IP addresses |
| `arns` | `list(string)` | EC2 instance ARNs |
| `instance_names` | `list(string)` | Generated Name tag values |

### Naming Convention

Instances are named using:
```
vm-<project_code>-<environment>-<network_zone>-<role>-<seq>
# Example: vm-cis-uat-ie-tvm-01
```

---

## Module 4: ECR (`modules/ecr`)

### Purpose
Creates multiple ECR repositories with KMS encryption, immutable image tags, scan-on-push, and lifecycle policies. All repos are driven by a map of configurations (from CSV).

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_ecr_repository` | Dynamic | One per repository in input map |
| `aws_ecr_lifecycle_policy` | Dynamic | One per repository |

### Input Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `repositories` | `map(object)` | ✅ | Map of repo configurations |

### Repository Object Structure

```hcl
repositories = {
  "frontend" = {
    project      = "cis"
    environment  = "uat"
    repo_name    = "frontend"
    mutability   = "IMMUTABLE"
    scan_on_push = true
    max_images   = 30
  }
}
```

### Security Features

```hcl
# Immutable tags — prevents overwriting published images
image_tag_mutability = "IMMUTABLE"

# KMS encryption — images encrypted at rest
encryption_configuration {
  encryption_type = "KMS"
}

# Scan every push — detect vulnerabilities automatically
image_scanning_configuration {
  scan_on_push = true
}
```

### Lifecycle Policy

Each repository keeps only the **last N images** (default: 30):

```json
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep only the last 30 images",
    "selection": {
      "tagStatus": "any",
      "countType": "imageCountMoreThan",
      "countNumber": 30
    },
    "action": { "type": "expire" }
  }]
}
```

### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `repository_urls` | `map(string)` | Map of service name → ECR URL |
| `repository_arns` | `map(string)` | Map of service name → ECR ARN |

### All 11 Repositories Created

| Service | ECR Repository Name |
|---------|-------------------|
| adservice | `cis-uat-adservice` |
| cartservice | `cis-uat-cartservice` |
| checkoutservice | `cis-uat-checkoutservice` |
| currencyservice | `cis-uat-currencyservice` |
| emailservice | `cis-uat-emailservice` |
| frontend | `cis-uat-frontend` |
| loadgenerator | `cis-uat-loadgenerator` |
| paymentservice | `cis-uat-paymentservice` |
| productcatalogservice | `cis-uat-productcatalogservice` |
| recommendationservice | `cis-uat-recommendationservice` |
| shippingservice | `cis-uat-shippingservice` |

---

## Module 5: EKS (`modules/eks`)

### Purpose
Creates an Amazon EKS cluster with KMS-encrypted Kubernetes secrets, full control plane logging, OIDC-ready configuration, managed node groups, and custom security group rules for the cluster's managed security group.

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_kms_key` | 1 | KMS key for K8s secret encryption |
| `aws_eks_cluster` | 1 | EKS control plane |
| `aws_security_group_rule` | Dynamic | Rules applied to EKS managed SG |
| `aws_eks_node_group` | Dynamic | One per entry in `node_groups` map |

### Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project` | `string` | ✅ | — | Project name for naming |
| `environment` | `string` | ✅ | — | Environment for naming |
| `cluster_name` | `string` | ✅ | — | Cluster identifier |
| `k8s_version` | `string` | ✅ | — | Kubernetes version (e.g., `1.31`) |
| `subnet_ids` | `list(string)` | ✅ | — | Subnet IDs for nodes |
| `endpoint_private` | `bool` | ✅ | — | Enable private API endpoint |
| `endpoint_public` | `bool` | ✅ | — | Enable public API endpoint |
| `cluster_role_arn` | `string` | ✅ | — | IAM role ARN for control plane |
| `node_role_arn` | `string` | ✅ | — | IAM role ARN for worker nodes |
| `node_groups` | `map(object)` | ✅ | — | Node group configurations |
| `cluster_security_group_ids` | `list(string)` | ✅ | — | Additional SG IDs for cluster |
| `vpc_sg_ids` | `map(string)` | ❌ | `{}` | VPC SG IDs for rule source lookup |
| `managed_sg_rules` | `any` | ❌ | `[]` | Rules for EKS managed SG |

### Node Group Object Structure

```hcl
node_groups = {
  "ng_app" = {
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 10
    desired_size   = 3
    disk_size      = 20
  }
}
```

### Security Features

```hcl
# KMS encryption for Kubernetes secrets
encryption_config {
  provider   { key_arn = aws_kms_key.eks_secrets.arn }
  resources  = ["secrets"]
}

# Full audit and control plane logging
enabled_cluster_log_types = [
  "api", "audit", "authenticator",
  "controllerManager", "scheduler"
]

# Dual authentication mode
access_config {
  authentication_mode = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
}
```

### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `cluster_endpoint` | `string` | K8s API server endpoint |
| `cluster_name` | `string` | EKS cluster name |
| `oidc_issuer_url` | `string` | OIDC URL (used for IRSA) |
| `cluster_certificate_authority_data` | `string` | CA data for kubeconfig |

---

## Module 6: S3 (`modules/s3`)

### Purpose
Creates multiple S3 buckets with versioning, AES256 server-side encryption, public access blocking, and globally unique naming (using account ID suffix).

### Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_s3_bucket` | Dynamic | One per bucket in map |
| `aws_s3_bucket_versioning` | Dynamic | One per bucket |
| `aws_s3_bucket_server_side_encryption_configuration` | Dynamic | One per bucket |
| `aws_s3_bucket_public_access_block` | Dynamic | One per bucket |

### Input Variables

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `project_code` | `string` | ✅ | — | Project code for naming |
| `environment` | `string` | ✅ | — | Environment for naming |
| `account_id` | `string` | ✅ | — | AWS account ID for uniqueness |
| `buckets` | `map(object)` | ✅ | — | Bucket configuration map |
| `common_tags` | `map(string)` | ❌ | `{}` | Common tags |

### Bucket Object Structure

```hcl
buckets = {
  "app-data" = {
    versioning      = true
    prevent_destroy = true
    owner           = "team-a"
  }
}
```

### Naming Convention

```
st-<project_code>-<environment>-<bucket_key>-<account_id>
# Example: st-cis-uat-app-data-485950501937
```

### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `bucket_names` | `map(string)` | Map of bucket role → bucket name |
| `bucket_arns` | `map(string)` | Map of bucket role → bucket ARN |
| `bucket_regional_domain_names` | `map(string)` | Map of bucket role → regional domain |
