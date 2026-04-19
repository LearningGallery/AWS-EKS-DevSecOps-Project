output "state_bucket_names" {
  description = "Map of Backend IDs to their globally unique S3 Bucket names"
  value = {
    for k, v in aws_s3_bucket.state : k => v.bucket
  }
}

output "dynamodb_table_names" {
  description = "Map of Backend IDs to their DynamoDB Table names"
  value = {
    for k, v in aws_dynamodb_table.locks : k => v.name
  }
}

output "deployed_account_id" {
  description = "The AWS Account ID where the state is hosted"
  value       = data.aws_caller_identity.current.account_id
}