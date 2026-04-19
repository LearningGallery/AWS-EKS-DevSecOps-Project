# ------------------------------------------------------------------------------
# GLOBAL ENVIRONMENT VARIABLES
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure into"
  type        = string
  default     = "ap-southeast-1"
}

/*
variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
  
  validation {
    condition     = length(var.project_code) == 3
    error_message = "Project code must be exactly 3 characters to comply with naming standards."
  }
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat, dev)"
  type        = string

  validation {
    condition     = length(var.environment) == 3
    error_message = "Environment must be exactly 3 characters (e.g., prd, uat)."
  }
}

variable "network_zone" {
  description = "2-character network zone (e.g., ia for intranet, ie for internet)"
  type        = string

  validation {
    condition     = length(var.network_zone) == 2
    error_message = "Network zone must be exactly 2 characters (e.g., ia, ie)."
  }
}

variable "vpc_cidr" {
  description = "The primary CIDR block for the Core VPC"
  type        = string
}
*/
