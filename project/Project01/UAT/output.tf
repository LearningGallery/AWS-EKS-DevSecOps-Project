/*
# ------------------------------------------------------------------------------
# VPC & NETWORK OUTPUTS
# ------------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the Core VPC"
  value       = module.vpc.vpc_id
}

output "subnet_ids_map" {
  description = "Map of all dynamically generated Subnet IDs"
  value       = module.vpc.subnet_ids
}

# ------------------------------------------------------------------------------
# EC2 COMPUTING OUTPUTS
# ------------------------------------------------------------------------------
output "ec2_private_ips" {
  description = "Map of EC2 tiers to their respective lists of private IP addresses"
  # Iterates through the EC2 module loop and extracts the private_ips list for each tier
  # Example output: { "web" = ["10.0.1.15", "10.0.2.45"], "db" = ["10.0.5.20"] }
  value = { for tier, outputs in module.ec2_infrastructure : tier => outputs.private_ips }
}

output "ec2_instance_ids" {
  description = "Map of EC2 tiers to their respective lists of instance IDs"
  value       = { for tier, outputs in module.ec2_infrastructure : tier => outputs.instance_ids }
}

# ------------------------------------------------------------------------------
# EKS KUBERNETES OUTPUTS
# ------------------------------------------------------------------------------
output "eks_cluster_name" {
  description = "The dynamically generated name of the EKS cluster"
  value       = module.core_eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "The private API endpoint for the EKS cluster"
  value       = module.core_eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Run this command in your terminal to authenticate with the new cluster"
  # This constructs the exact AWS CLI command needed to link kubectl to the cluster
  value       = "aws eks update-kubeconfig --region ap-southeast-1 --name ${module.core_eks.cluster_name}"
}

# ------------------------------------------------------------------------------
# ECR CONTAINER REGISTRY OUTPUTS
# ------------------------------------------------------------------------------
output "ecr_repository_urls" {
  description = "Map of repository names to their push/pull URLs"
  value       = module.core_ecr.repository_urls
}

# ------------------------------------------------------------------------------
# S3 PLATFORM BUCKET OUTPUTS
# ------------------------------------------------------------------------------
output "s3_platform_buckets" {
  description = "Map of platform bucket roles to their globally unique names"
  value       = module.core_s3.bucket_names
}

# ------------------------------------------------------------------------------
# IAM IDENTITY OUTPUTS
# ------------------------------------------------------------------------------
output "iam_role_arns" {
  description = "Map of created IAM roles and their ARNs"
  value       = module.core_iam.role_arns
}
*/
