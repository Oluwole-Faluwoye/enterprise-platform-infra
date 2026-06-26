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
  value = var.enable_jenkins ? module.iam[0].terraform_role_arn : null
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