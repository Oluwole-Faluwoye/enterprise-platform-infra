output "jenkins_ip" {
  value = var.enable_jenkins ? module.jenkins[0].public_ip : null
}

output "app_ecr_repo" {
  value = module.app_ecr[0].repository_url
}

output "jenkins_ecr_repo" {
  value = module.jenkins_ecr[0].repository_url
}

output "terraform_deployer_role_arn" {

  value = var.enable_jenkins ? module.iam[0].terraform_role_arn : null
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}