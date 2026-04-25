# ------------------------------------------------------------------------------
# GLOBAL ENVIRONMENT VARIABLES
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure into"
  type        = string
  default     = "ap-southeast-1"
}
