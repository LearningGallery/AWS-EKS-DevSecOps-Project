output "bucket_names" {
  description = "Map of bucket roles to their globally unique S3 bucket names"
  # Example output: { "app-data" = "st-cis-prd-app-data-123456789012" }
  value = { for k, v in aws_s3_bucket.this : k => v.bucket }
}

output "bucket_arns" {
  description = "Map of bucket roles to their ARNs (useful for strict IAM policies)"
  # Example output: { "team-a-state" = "arn:aws:s3:::st-cis-prd-team-a-state-123456789012" }
  value = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket roles to their regional domain names (useful for CDN or DNS mapping)"
  value = { for k, v in aws_s3_bucket.this : k => v.bucket_regional_domain_name }
}