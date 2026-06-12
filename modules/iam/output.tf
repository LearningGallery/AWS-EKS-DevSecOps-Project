output "instance_profile_names" {
  description = "Map of Instance Profile names keyed by role_id"
  value       = { for k, v in aws_iam_instance_profile.profile : k => v.name }
}

output "role_arns" {
  description = "Map of IAM Role ARNs keyed by role_id"
  value       = { for k, v in aws_iam_role.role : k => v.arn }
}