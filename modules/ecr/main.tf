resource "aws_ecr_repository" "this" {
  for_each             = var.repositories
  name                 = "cr-${var.project_code}-${var.environment}-${each.value.repo_name}"
  image_tag_mutability = each.value.mutability
  
  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }
  
  encryption_configuration {
    encryption_type = "KMS" # Enterprise default
  }
}