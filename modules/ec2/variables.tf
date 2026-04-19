# --- Naming Convention Variables ---

variable "project_code" {
  description = "3-character project code (e.g., cis)"
  type        = string
}

variable "environment" {
  description = "Environment tier (e.g., prd, uat)"
  type        = string
}

variable "network_zone" {
  description = "2-character network zone (e.g., ia for intranet)"
  type        = string
}

variable "role" {
  description = "3-character server role derived from CSV (e.g., web, app)"
  type        = string
}

# --- Compute Variables ---

variable "instance_count" {
  description = "Number of instances to deploy for this tier"
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "List of instance types parsed from CSV. element() wraps around this list."
  type        = list(string)
}

variable "ami_id" {
  description = "AMI ID to use for the instances"
  type        = string
}

# --- Network & Security Variables ---

variable "subnet_ids" {
  description = "List of Subnet IDs mapped dynamically from the VPC module"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of Security Group IDs mapped dynamically from the VPC module"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "Name of the IAM Instance Profile mapped dynamically from the IAM module"
  type        = string
  default     = null
}

# --- Storage Variables ---

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of root volume (e.g., gp3)"
  type        = string
  default     = "gp3"
}

variable "encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

# --- Operational Variables ---

variable "user_data" {
  description = "File contents of the bootstrap script parsed from the scripts directory"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to apply to the instances and volumes"
  type        = map(string)
  default     = {}
}