output "repository_urls" {
  description = "Map of repository names to their repository URLs"
  # Example output: { "frontend-app" = "123456789012.dkr.ecr.ap-southeast-1.amazonaws.com/cr-cis-prd-frontend-app" }
  value = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}