# 📝 Variables Guide

---

## 1. Variable Architecture Overview

This project uses a **CSV-driven data engine** instead of traditional `terraform.tfvars`. 
Think of it like this:

```
Traditional Terraform:          This Project:
variables.tf (define)           variables.tf (define)
terraform.tfvars (set values)   data/*.csv (set values)
                                main.tf locals (parse CSV → maps)
```

The key benefit: **infrastructure teams can edit a spreadsheet instead of writing HCL**.

---

## 2. Variable Hierarchy

```
Priority (highest to lowest):
  1. Command-line flags:    terraform apply -var="aws_region=us-east-1"
  2. Environment variables: TF_VAR_aws_region=us-east-1
  3. terraform.tfvars:      aws_region = "us-east-1"
  4. variables.tf defaults: default = "ap-southeast-1"
  5. CSV data files:        data/vpcs.csv (not standard Terraform variables)
```

---

## 3. Root Module Variables (`variables.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | `string` | `ap-southeast-1` | AWS region for all resources |

### Usage

```hcl
# Override via command line
terraform apply -var="aws_region=us-east-1"

# Override via environment variable
export TF_VAR_aws_region="us-east-1"

# Override via tfvars file
echo 'aws_region = "us-east-1"' > terraform.tfvars
```

---

## 4. CSV Data Files Reference

### 4.1 `data/vpcs.csv` — VPC Configuration

Controls what VPCs are created.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `vpc_id` | string | ✅ | `core` | Unique identifier used as map key |
| `project` | string | ✅ | `cis` | Project code (3 chars) |
| `env` | string | ✅ | `uat` | Environment tag |
| `cidr_block` | string | ✅ | `10.0.0.0/16` | VPC CIDR range |
| `network_zone` | string | ✅ | `ia` | Network zone code (2 chars) |

**Current configuration:**
```csv
vpc_id,project,env,cidr_block,network_zone
core,cis,uat,10.0.0.0/16,ia
```

**To add a second VPC:**
```csv
vpc_id,project,env,cidr_block,network_zone
core,cis,uat,10.0.0.0/16,ia
dmz,cis,uat,172.16.0.0/16,dmz
```

---

### 4.2 `data/subnets.csv` — Subnet Layout

Controls all subnets created within each VPC.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `id` | string | ✅ | `web_az1` | Unique subnet key (used in other CSVs) |
| `vpc_id` | string | ✅ | `core` | References `vpcs.csv` vpc_id |
| `cidr_block` | string | ✅ | `10.0.1.0/24` | Subnet CIDR range |
| `az` | string | ✅ | `ap-southeast-1a` | Availability zone |
| `is_public` | bool | ✅ | `true` | Whether subnet is public |
| `role` | string | ✅ | `web` | Subnet role (groups for SG/NACL/RT) |

**Current configuration:**
```csv
id,vpc_id,cidr_block,az,is_public,role
web_az1,core,10.0.1.0/24,ap-southeast-1a,true,web
web_az2,core,10.0.2.0/24,ap-southeast-1b,true,web
eks_az1,core,10.0.10.0/24,ap-southeast-1a,false,eks
eks_az2,core,10.0.11.0/24,ap-southeast-1b,false,eks
```

**To add a private app subnet:**
```csv
app_az1,core,10.0.20.0/24,ap-southeast-1a,false,app
```

---

### 4.3 `data/sg_rules.csv` — Security Group Rules

Controls all security group firewall rules.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `vpc_id` | string | ✅ | `core` | References `vpcs.csv` vpc_id |
| `sg_role` | string | ✅ | `web` | Security group role name |
| `type` | string | ✅ | `ingress` | `ingress` or `egress` |
| `from_port` | number | ✅ | `443` | Start port |
| `to_port` | number | ✅ | `443` | End port |
| `protocol` | string | ✅ | `tcp` | `tcp`, `udp`, `-1` (all) |
| `source_type` | string | ✅ | `cidr` | `cidr` or `sg` |
| `source` | string | ✅ | `0.0.0.0/0` | CIDR block or SG role name |
| `description` | string | ✅ | `Allow HTTPS` | Rule description |

> **Special value:** `sg_role = "eks_default"` — rules with this role are applied to the EKS cluster's **managed security group** (not the VPC SG), to avoid circular dependencies.

**To add a new rule:**
```csv
core,web,ingress,8443,8443,tcp,cidr,0.0.0.0/0,Allow Alt HTTPS
```

---

### 4.4 `data/nacl_rules.csv` — Network ACL Rules

Controls stateless packet filtering at the subnet level.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `vpc_id` | string | ✅ | `core` | References `vpcs.csv` vpc_id |
| `nacl_role` | string | ✅ | `web` | Maps to subnet role |
| `rule_no` | number | ✅ | `100` | Rule priority (lower = evaluated first) |
| `type` | string | ✅ | `ingress` | `ingress` or `egress` |
| `action` | string | ✅ | `allow` | `allow` or `deny` |
| `from_port` | number | ✅ | `443` | Start port |
| `to_port` | number | ✅ | `443` | End port |
| `protocol` | string | ✅ | `tcp` | `tcp`, `udp`, `-1` (all) |
| `cidr_block` | string | ✅ | `0.0.0.0/0` | Source/destination CIDR |

> **Note:** Rule numbers must be unique per `nacl_role` + `type` combination.

---

### 4.5 `data/route_rules.csv` — Route Table Rules

Controls routing entries in route tables.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `vpc_id` | string | ✅ | `core` | References `vpcs.csv` vpc_id |
| `route_table_role` | string | ✅ | `pub` | `pub` for public RT, or private role name |
| `destination_cidr` | string | ✅ | `0.0.0.0/0` | Destination CIDR |
| `target_type` | string | ✅ | `igw` | `igw` (Internet Gateway) |

**Current configuration:**
```csv
vpc_id,route_table_role,destination_cidr,target_type
core,pub,0.0.0.0/0,igw
```

**To add a NAT Gateway route (when NAT is added):**
```csv
core,eks,0.0.0.0/0,nat
```

---

### 4.6 `data/iam_roles.csv` — IAM Role Definitions

Controls all IAM roles, their trust relationships, and policy attachments.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `role_id` | string | ✅ | `eks-master` | Unique role identifier (map key) |
| `project` | string | ✅ | `cis` | Project code |
| `env` | string | ✅ | `uat` | Environment |
| `trusted_service` | string | ✅ | `eks.amazonaws.com` | AWS service principal |
| `managed_policies` | string | ✅ | `arn:aws:iam::aws:policy/...` | Semicolon-separated ARNs |
| `custom_policy_file` | string | ❌ | `policies/eks_custom_policy.json` | Path to custom policy JSON |
| `create_instance_profile` | bool | ✅ | `true` | Whether to create instance profile |
| `eks_access_policy` | string | ❌ | `arn:aws:eks::aws:cluster-access-policy/...` | EKS access policy ARN |

**Current roles:**

| role_id | Purpose | Instance Profile |
|---------|---------|-----------------|
| `ec2-profile` | Management EC2 + EKS admin access | ✅ Yes |
| `eks-master` | EKS control plane | ❌ No |
| `eks-node` | EKS worker nodes | ✅ Yes |

---

### 4.7 `data/infrastructure.csv` — EC2 Instance Definitions

Controls all EC2 instances provisioned via the EC2 module.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `tier` | string | ✅ | `mgm` | Unique tier name (map key) |
| `vpc_id` | string | ✅ | `core` | References VPC |
| `project` | string | ✅ | `cis` | Project code |
| `env` | string | ✅ | `uat` | Environment |
| `zone` | string | ✅ | `ie` | Network zone |
| `role` | string | ✅ | `tvm` | Server role for naming |
| `count` | number | ✅ | `1` | Number of instances |
| `instance_types` | string | ✅ | `t3.medium` | Semicolon-separated list |
| `ami_id` | string | ✅ | `ami-03c3282f979a6a9b0` | AMI ID |
| `key_name` | string | ❌ | `learninggallery` | SSH key pair name |
| `subnet_ids` | string | ✅ | `web_az1` | Semicolon-separated subnet keys |
| `sg_ids` | string | ✅ | `sg-web` | Semicolon-separated SG keys |
| `iam_profile` | string | ❌ | `ec2-profile` | IAM role_id for instance profile |
| `vol_size` | number | ✅ | `30` | Root volume size in GB |
| `vol_type` | string | ✅ | `gp3` | EBS volume type |
| `vol_encrypt` | bool | ✅ | `true` | Volume encryption |
| `public_ip` | bool | ✅ | `true` | Associate public IP |
| `userdata_file` | string | ❌ | `scripts/updated_install-tools.sh` | Bootstrap script path |

**Current instance:**
```csv
tier: mgm
Type: t3.medium
Subnet: web_az1 (public, ap-southeast-1a)
Role: tvm (tooling/management VM)
Bootstrap: updated_install-tools.sh (Jenkins, Docker, Trivy, kubectl, etc.)
```

---

### 4.8 `data/ecr_repositories.csv` — ECR Repository Definitions

Controls all ECR repositories created.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `project` | string | ✅ | `cis` | Project code |
| `environment` | string | ✅ | `uat` | Environment |
| `service_name` | string | ✅ | `frontend` | Service name (becomes repo name suffix) |
| `image_mutability` | string | ✅ | `IMMUTABLE` | `IMMUTABLE` or `MUTABLE` |
| `scan_on_push` | bool | ✅ | `TRUE` | Enable vulnerability scanning |
| `max_images` | number | ✅ | `30` | Maximum images to retain |

---

### 4.9 `data/eks_clusters.csv` — EKS Cluster Configuration

Controls EKS clusters created.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `cluster_id` | string | ✅ | `eks_main` | Unique cluster identifier |
| `project` | string | ✅ | `cis` | Project code |
| `environment` | string | ✅ | `uat` | Environment |
| `k8s_version` | string | ✅ | `1.31` | Kubernetes version |
| `vpc_id` | string | ✅ | `core` | References `vpcs.csv` |
| `subnet_ids` | string | ✅ | `web_az1;web_az2` | Semicolon-separated subnet keys |
| `endpoint_private` | bool | ✅ | `true` | Enable private API endpoint |
| `endpoint_public` | bool | ✅ | `true` | Enable public API endpoint |
| `cluster_iam_role` | string | ✅ | `eks-master` | References `iam_roles.csv` role_id |
| `node_iam_role` | string | ✅ | `eks-node` | References `iam_roles.csv` role_id |
| `cluster_sg` | string | ❌ | `web` | Security group role for cluster |

---

### 4.10 `data/eks_node_groups.csv` — EKS Node Group Configuration

Controls EKS managed node groups.

| Column | Type | Required | Example | Description |
|--------|------|----------|---------|-------------|
| `ng_id` | string | ✅ | `ng_app` | Unique node group identifier |
| `cluster_id` | string | ✅ | `eks_main` | References `eks_clusters.csv` |
| `instance_types` | string | ✅ | `t3.large` | Semicolon-separated instance types |
| `capacity_type` | string | ✅ | `ON_DEMAND` | `ON_DEMAND` or `SPOT` |
| `min_size` | number | ✅ | `2` | Minimum node count |
| `max_size` | number | ✅ | `10` | Maximum node count |
| `desired_size` | number | ✅ | `3` | Desired node count |
| `disk_size` | number | ✅ | `20` | Node disk size in GB |

---

## 5. Bootstrap Module Variables (`terraform-bootstrap/variables.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | `string` | `ap-southeast-1` | Bootstrap deployment region |
| `project_code` | `string` | `cis` | Project code |
| `environment` | `string` | `prd` | Environment (note: defaults to `prd`) |
| `common_tags` | `map(string)` | See below | Tags applied to bootstrap resources |

```hcl
common_tags = {
  ManagedBy = "Terraform-Bootstrap"
  Role      = "Infrastructure-State"
}
```

---

## 6. Common Customisation Patterns

### Change Kubernetes Version

```csv
# data/eks_clusters.csv
cluster_id,k8s_version,...
eks_main,1.32,...
```

### Add SPOT Instances to Node Group

```csv
# data/eks_node_groups.csv
ng_id,cluster_id,instance_types,capacity_type,...
ng_spot,eks_main,t3.large;t3.xlarge,SPOT,1,20,3,20
```

### Scale Node Group

```csv
# data/eks_node_groups.csv — change desired/max
ng_app,eks_main,t3.large,ON_DEMAND,2,20,5,20
```

### Add a New Microservice ECR Repo

```csv
# data/ecr_repositories.csv — add a row
cis,uat,newservice,IMMUTABLE,TRUE,30
```
