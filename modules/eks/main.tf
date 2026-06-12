# -----------------------------------------------------------------------------
# Zero Trust: KMS Key for Envelope Encryption of K8s Secrets
# -----------------------------------------------------------------------------
resource "aws_kms_key" "eks_secrets" {
  description             = "EKS Secret Encryption Key for ${var.project}-${var.environment}-${var.cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags = { Environment = var.environment, Project = var.project }
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.project}-${var.environment}-${var.cluster_name}"
  
  # Uses the externally created IAM role
  role_arn = var.cluster_role_arn 
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private
    endpoint_public_access  = var.endpoint_public
    security_group_ids      = var.cluster_security_group_ids
  }

  # Add this block right here!
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  encryption_config {
    provider { key_arn = aws_kms_key.eks_secrets.arn }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

resource "aws_security_group_rule" "eks_managed_rules" {
  for_each = { for r in var.managed_sg_rules : 
    "${r.sg_role}-${r.type}-${r.protocol}-${r.from_port}-${r.to_port}-${r.source}" => r 
  }

  # This targets the hidden SG AWS created for the cluster
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  type      = each.value.type
  from_port = tonumber(each.value.from_port)
  to_port   = tonumber(each.value.to_port)
  protocol  = each.value.protocol

  cidr_blocks = each.value.source_type == "cidr" ? [each.value.source] : null
  
  # Look up the VPC SG IDs from the map we pass in
  source_security_group_id = each.value.source_type == "sg" ? var.vpc_sg_ids["sg-${each.value.source}"] : null
}

# -----------------------------------------------------------------------------
# EKS Node Groups (Supports multiple node groups per cluster)
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "nodes" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project}-${var.environment}-${each.key}"
  
  # Uses the externally created IAM role
  node_role_arn   = var.node_role_arn 
  
  subnet_ids      = var.subnet_ids
  capacity_type   = each.value.capacity_type
  instance_types  = each.value.instance_types
  disk_size       = each.value.disk_size

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = 1
  }
}