
output "cluster_name" {
  value = var.enable_eks ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  value = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_security_group_id" {
  value = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}