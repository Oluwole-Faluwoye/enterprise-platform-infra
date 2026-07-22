output "cluster_name" {

  value = var.enable_eks ? module.eks[0].cluster_name : null

}

output "cluster_endpoint" {

  value = var.enable_eks ? module.eks[0].cluster_endpoint : null

}

output "cluster_security_group_id" {

  value = var.enable_eks ? module.eks[0].cluster_security_group_id : null

}

output "secret_arns" {

  description = "Map of Secrets Manager ARNs"

  value = module.secrets_manager.secret_arns

}

output "hosted_zone_id" {

  value = module.route53.hosted_zone_id

}

output "hosted_zone_name_servers" {

  value = module.route53.hosted_zone_name_servers

}

output "certificate_arn" {

  description = "ACM Certificate ARN"

  value = module.acm.certificate_arn

}

output "certificate_domain" {

  description = "Certificate Domain"

  value = module.acm.certificate_domain

}

output "aws_load_balancer_controller_role_arn" {
  value = var.enable_eks ? module.iam_irsa[0].aws_load_balancer_controller_role_arn : null
}

output "external_dns_role_arn" {
  value = var.enable_eks ? module.iam_irsa[0].external_dns_role_arn : null
}

output "vpc_id" {
  value = data.terraform_remote_state.bootstrap.outputs.vpc_id
}