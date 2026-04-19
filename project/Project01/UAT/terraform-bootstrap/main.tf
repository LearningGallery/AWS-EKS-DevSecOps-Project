provider "aws" {
  region = var.aws_region
}

# Dynamically fetch the AWS Account ID for globally unique bucket names
data "aws_caller_identity" "current" {}

locals {
  # 1. Read and decode the CSV
  raw_backends = csvdecode(file("${path.module}/../data/bootstrap_backends.csv"))

  # 2. Convert to a map using 'id' as the key
  backend_map = {
    for row in local.raw_backends : row.id => row
  }
}

# ------------------------------------------------------------------------------
# 1. S3 BUCKETS FOR STATE STORAGE
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  for_each = local.backend_map

  # Naming: st-[project]-[env]-[role]-[account_id]
  bucket = "st-${each.value.project}-${each.value.env}-${each.value.bucket_role}-${data.aws_caller_identity.current.account_id}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.common_tags, {
    Name        = "st-${each.value.project}-${each.value.env}-${each.value.bucket_role}"
    Project     = each.value.project
    Environment = each.value.env
  })
}

resource "aws_s3_bucket_versioning" "state" {
  for_each = local.backend_map

  bucket = aws_s3_bucket.state[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  for_each = local.backend_map

  bucket = aws_s3_bucket.state[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  for_each = local.backend_map

  bucket                  = aws_s3_bucket.state[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 2. DYNAMODB TABLES FOR STATE LOCKING
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "locks" {
  for_each = local.backend_map

  # Naming: tb-[project]-[env]-[role]
  name         = "tb-${each.value.project}-${each.value.env}-${each.value.table_role}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.common_tags, {
    Name        = "tb-${each.value.project}-${each.value.env}-${each.value.table_role}"
    Project     = each.value.project
    Environment = each.value.env
  })
}