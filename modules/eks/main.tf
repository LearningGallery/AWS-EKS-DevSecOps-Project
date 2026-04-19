resource "aws_eks_cluster" "this" {
  name     = "ek-${var.project_code}-${var.environment}-${var.network_zone}-${var.cluster_name}"
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true  # GCC Secure Default
    endpoint_public_access  = false
  }
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "ng-${var.project_code}-${var.environment}-default"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
  instance_types = ["t3.large"]
}