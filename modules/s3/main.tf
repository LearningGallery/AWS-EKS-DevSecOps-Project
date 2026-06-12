# 1. The Bucket
resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  
  # Naming: st-[project]-[env]-[role]-[account_id] (Account ID ensures global uniqueness)
  bucket = "st-${var.project_code}-${var.environment}-${each.key}-${var.account_id}"

  tags = merge(var.common_tags, {
    Name  = "st-${var.project_code}-${var.environment}-${each.key}"
    Owner = each.value.owner
  })
}

# 2. Versioning Configuration
resource "aws_s3_bucket_versioning" "this" {
  for_each = var.buckets
  
  bucket = aws_s3_bucket.this[each.key].id
  versioning_configuration {
    status = each.value.versioning ? "Enabled" : "Suspended"
  }
}

# 3. Enterprise Default Encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = var.buckets
  
  bucket = aws_s3_bucket.this[each.key].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Mandatory Public Access Block
resource "aws_s3_bucket_public_access_block" "this" {
  for_each = var.buckets
  
  bucket                  = aws_s3_bucket.this[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output the bucket names for reference
