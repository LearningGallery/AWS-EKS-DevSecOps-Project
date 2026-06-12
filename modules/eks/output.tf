output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "oidc_issuer_url" {
  description = "Exported for the IAM module to construct the OIDC provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_certificate_authority_data" {
  description = "Required to configure the Kubernetes provider later"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}