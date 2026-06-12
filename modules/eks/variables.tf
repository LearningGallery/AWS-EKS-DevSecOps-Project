variable "project" { type = string }
variable "environment" { type = string }
variable "cluster_name" { type = string }
variable "k8s_version" { type = string }
variable "subnet_ids" { type = list(string) }
variable "endpoint_private" { type = bool }
variable "endpoint_public" { type = bool }
variable "cluster_role_arn" { 
  description = "The ARN of the IAM role for the EKS control plane"
  type        = string 
}
variable "node_role_arn" { 
  description = "The ARN of the IAM role for the EKS worker nodes"
  type        = string 
}
variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
  }))
}

variable "cluster_security_group_ids" {
  description = "List of Security Group IDs to attach to the EKS Control Plane"
  type        = list(string)
}

variable "vpc_sg_ids" {
  description = "Map of security group IDs from the VPC module"
  type        = map(string)
  default     = {}
}

variable "managed_sg_rules" {
  description = "List of rules filtered from the CSV specifically for the managed SG"
  type        = any
  default     = []
}