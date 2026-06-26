output "cluster_name" {
  value = module.eks[0].cluster_name
}

output "cluster_endpoint" {
  value = module.eks[0].cluster_endpoint
}

output "cluster_security_group_id" {
  value = module.eks[0].cluster_security_group_id
}