# Convert the incoming list into a map for the for_each loop
locals {
  repos = { for repo in var.repositories : repo.repo_name => repo }
}

# -----------------------------------------------------------------------------
# ECR Repositories (Zero Trust & KMS Encrypted)
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "registry" {
  for_each = local.repos

  # Standard Naming Convention: project/environment/service
  name                 = "${each.value.project}/${each.value.environment}/${each.value.repo_name}"
  
  # Supply Chain Security: Prevent tag overwriting
  image_tag_mutability = each.value.mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = each.value.scan_on_push
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Environment = each.value.environment
    Project     = each.value.project
    Service     = each.value.repo_name
    ManagedBy   = "Terraform"
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Policies (Cost Optimization)
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = local.repos
  repository = aws_ecr_repository.registry[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep only the last ${each.value.max_images} images to optimize storage costs",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = tonumber(each.value.max_images)
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}