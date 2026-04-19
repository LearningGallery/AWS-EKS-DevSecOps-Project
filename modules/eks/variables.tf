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

variable "cluster_name" {
  description = "Logical name of the cluster"
  type        = string
  default     = "main"
}

variable "subnet_ids" {
  description = "List of Subnet IDs where the EKS control plane and worker nodes will be placed"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "IAM Role ARN for the EKS Cluster control plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM Role ARN for the EKS Worker Nodes"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to EKS resources"
  type        = map(string)
  default     = {}
}