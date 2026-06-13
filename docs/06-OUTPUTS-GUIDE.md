# 📤 Outputs Guide

---

## 1. Output Architecture

Outputs flow from **child modules → root module → consumer**:

```
modules/eks/output.tf
    └── cluster_endpoint
            └── module.core_eks["eks_main"].cluster_endpoint
                    └── root output.tf (currently commented out)
                            └── available via: terraform output
```

> **Note:** Root outputs in `output.tf` are currently commented out. 
> Uncomment them to expose values after `terraform apply`.

---

## 2. How to View Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output eks_cluster_name

# Output as JSON (useful for scripting)
terraform output -json

# Use in shell scripts
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region ap-southeast-1 --name $CLUSTER_NAME
```

---

## 3. Root Module Outputs

These are defined in `output.tf` (currently commented — uncomment to activate):

### VPC Outputs

```hcl
output "vpc_id" {
  description = "The ID of the Core VPC"
  value       = module.core_vpc["core"].vpc_id
}
# Example: vpc-0a1b2c3d4e5f67890

output "subnet_ids_map" {
  description = "Map of all dynamically generated Subnet IDs"
  value       = module.core_vpc["core"].subnet_ids
}
# Example:
# {
#   "web_az1" = "subnet-0123456789abcdef0"
#   "web_az2" = "subnet-0abcdef1234567890"
#   "eks_az1" = "subnet-0fedcba9876543210"
#   "eks_az2" = "subnet-0987654321fedcba0"
# }
```

### EC2 Outputs

```hcl
output "ec2_private_ips" {
  description = "Map of EC2 tiers to their private IP addresses"
  value       = { for tier, outputs in module.ec2_infrastructure : tier => outputs.private_ips }
}
# Example: { "mgm" = ["10.0.1.45"] }

output "ec2_instance_ids" {
  description = "Map of EC2 tiers to their instance IDs"
  value       = { for tier, outputs in module.ec2_infrastructure : tier => outputs.instance_ids }
}
# Example: { "mgm" = ["i-0123456789abcdef0"] }
```

### EKS Outputs

```hcl
output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.core_eks["eks_main"].cluster_name
}
# Example: cis-uat-eks_main

output "eks_cluster_endpoint" {
  description = "The EKS API server endpoint"
  value       = module.core_eks["eks_main"].cluster_endpoint
}
# Example: https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com

output "eks_kubeconfig_command" {
  description = "Run this command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ap-southeast-1 --name ${module.core_eks["eks_main"].cluster_name}"
}
# Example: aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main
```

### ECR Outputs

```hcl
output "ecr_repository_urls" {
  description = "Map of repository names to their ECR URLs"
  value       = module.core_ecr.repository_urls
}
# Example:
# {
#   "frontend"    = "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-frontend"
#   "adservice"   = "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-adservice"
#   ...
# }
```

### IAM Outputs

```hcl
output "iam_role_arns" {
  description = "Map of IAM role IDs to their ARNs"
  value       = module.core_iam.role_arns
}
# Example:
# {
#   "ec2-profile" = "arn:aws:iam::485950501937:role/rl-cis-uat-ec2-profile"
#   "eks-master"  = "arn:aws:iam::485950501937:role/rl-cis-uat-eks-master"
#   "eks-node"    = "arn:aws:iam::485950501937:role/rl-cis-uat-eks-node"
# }
```

---

## 4. Bootstrap Module Outputs

These are always active in `terraform-bootstrap/outputs.tf`:

```hcl
output "state_bucket_names" {
  value = { "core_uat" = "st-cis-uat-tfstate-485950501937" }
}

output "dynamodb_table_names" {
  value = { "core_uat" = "tb-cis-uat-tflocks" }
}

output "deployed_account_id" {
  value = "485950501937"
}
```

---

## 5. Using Outputs in Other Terraform Configurations

Use `terraform_remote_state` to consume outputs in another config:

```hcl
data "terraform_remote_state" "uat_infra" {
  backend = "s3"
  config = {
    bucket = "st-cis-uat-tfstate-485950501937"
    key    = "core-infra/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# Reference the EKS cluster endpoint
resource "helm_release" "argocd" {
  ...
  # Use the remote state output
  cluster = data.terraform_remote_state.uat_infra.outputs.eks_cluster_endpoint
}
```

---

## 6. Activating Root Outputs

To enable root outputs, uncomment `output.tf`:

```bash
# Edit the file
vim Project/LearningGallery/Infra-Code_UAT/output.tf

# Remove /* and */ comment blocks
# Then apply:
terraform apply -refresh-only
terraform output
```
