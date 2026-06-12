variable "aws_region" {
  description = "The AWS region to deploy the bootstrap resources into"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
  default     = "cis"
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat)"
  type        = string
  default     = "prd"
}

variable "common_tags" {
  description = "Tags to apply to all bootstrap resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform-Bootstrap"
    Role      = "Infrastructure-State"
  }
}