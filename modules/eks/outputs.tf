# =========================================================
# EKS CLUSTER OUTPUTS
# =========================================================

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "EKS Cluster Security Group ID"
  value       = module.eks.cluster_security_group_id
}

output "cluster_arn" {
  description = "EKS Cluster ARN"
  value       = module.eks.cluster_arn
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "OIDC Provider URL"
  value       = module.eks.oidc_provider
}

output "node_group_role_arn" {
  description = "Node Group IAM Role ARN"
  value       = module.eks.eks_managed_node_groups["devops_nodes"].iam_role_arn
}