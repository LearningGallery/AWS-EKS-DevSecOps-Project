variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat)"
  type        = string
}

variable "roles" {
  description = "Map of role configurations parsed from the CSV"
  type = map(object({
    trusted_service  = string
    managed_policies = list(string)
  }))
}

variable "common_tags" {
  description = "Common tags to apply to all IAM resources"
  type        = map(string)
  default     = {}
}