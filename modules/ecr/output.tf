output "repository_urls" {
  description = "Map of service names to their respective ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.registry : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of service names to their respective ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.registry : k => v.arn }
}