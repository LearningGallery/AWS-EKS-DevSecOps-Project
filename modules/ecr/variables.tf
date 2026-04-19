variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat)"
  type        = string
}

variable "repositories" {
  description = "Map of ECR repository configurations parsed from ecr_repos.csv"
  type = map(object({
    repo_name    = string
    mutability   = string # e.g., MUTABLE or IMMUTABLE
    scan_on_push = bool
  }))
}

variable "common_tags" {
  description = "Common tags to apply to all ECR repositories"
  type        = map(string)
  default     = {}
}