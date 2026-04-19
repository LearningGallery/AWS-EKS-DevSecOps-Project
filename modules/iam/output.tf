output "instance_profile_names" {
  description = "Map of role_ids to their generated Instance Profile names. Used for EC2 attachments."
  # Example output: { "app_role" = "profile-cis-prd-app_role" }
  value = { for k, v in aws_iam_instance_profile.this : k => v.name }
}

output "role_arns" {
  description = "Map of role_ids to their generated IAM Role ARNs. Used for EKS and cross-service attachments."
  # Example output: { "eks_cluster_role" = "arn:aws:iam::123456789012:role/role-cis-prd-eks_cluster_role" }
  value = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of role_ids to their generated IAM Role Names. Useful for inline policy attachments."
  # Example output: { "db_role" = "role-cis-prd-db_role" }
  value = { for k, v in aws_iam_role.this : k => v.name }
}