output "jenkins_ip" {
  value = var.enable_jenkins ? module.jenkins[0].public_ip : null
}

output "app_ecr_repo" {
  value = module.app_ecr[0].repository_url
}

output "allowed_jenkins_ssh_cidrs" {
  value = var.allowed_jenkins_ssh_cidrs
}

output "jenkins_ecr_repo" {
  value = module.jenkins_ecr[0].repository_url
}

output "jenkins_role_arn" {
  value = var.enable_jenkins ? module.jenkins[0].jenkins_role_arn : null
}

output "terraform_deployer_role_arn" {
  value = var.enable_jenkins ? module.iam_bootstrap[0].terraform_role_arn : null
}

# =====================================================
# Outputs consumed by Platform State
# =====================================================

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "jenkins_security_group_id" {
  value = var.enable_jenkins ? module.jenkins[0].security_group_id : null
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnets
}

output "public_route_table_ids" {
  value = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  value = module.vpc.private_route_table_ids
}

# =========================================================
# DATABASE REGISTRY
# =========================================================

output "database_registry_table_name" {

  description = "Persistent platform database registry table"

  value = module.database_registry_store.table_name

}


output "database_registry_table_arn" {

  description = "Persistent platform database registry table ARN"

  value = module.database_registry_store.table_arn

}