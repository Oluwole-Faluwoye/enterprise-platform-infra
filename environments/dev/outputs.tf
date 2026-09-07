# =========================================================
# ENVIRONMENT NETWORKING
# =========================================================

output "vpc_id" {
  description = "DEV environment VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnets" {
  description = "DEV public subnet IDs"
  value       = module.networking.public_subnets
}

output "private_subnets" {
  description = "DEV private subnet IDs"
  value       = module.networking.private_subnets
}

output "database_subnets" {
  description = "DEV database subnet IDs"
  value       = module.networking.database_subnets
}

output "nat_gateway_ids" {
  description = "DEV NAT Gateway IDs"
  value       = module.networking.nat_gateway_ids
}

# =========================================================
# EKS
# =========================================================

output "cluster_name" {
  value = var.enable_eks ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  value = var.enable_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_security_group_id" {
  value = var.enable_eks ? module.eks[0].cluster_security_group_id : null
}

# =========================================================
# SECRETS
# =========================================================

output "secret_arns" {
  description = "Map of Secrets Manager ARNs"
  value       = module.secrets_manager.secret_arns
}

# =========================================================
# DNS
# =========================================================

output "hosted_zone_id" {
  value = module.route53.hosted_zone_id
}

output "hosted_zone_name_servers" {
  value = module.route53.hosted_zone_name_servers
}

# =========================================================
# ACM
# =========================================================

output "certificate_arn" {
  description = "ACM Certificate ARN"
  value       = module.acm.certificate_arn
}

output "certificate_domain" {
  description = "Certificate Domain"
  value       = module.acm.certificate_domain
}

# =========================================================
# IRSA
# =========================================================

output "aws_load_balancer_controller_role_arn" {
  value = var.enable_eks ? module.iam_irsa[0].aws_load_balancer_controller_role_arn : null
}

output "external_dns_role_arn" {
  value = var.enable_eks ? module.iam_irsa[0].external_dns_role_arn : null
}

# =========================================================
# ENVIRONMENT CONTEXT
# =========================================================

output "environment_context" {
  description = "Infrastructure context consumed by platform provisioning"

  value = {
    vpc_id              = module.networking.vpc_id
    private_subnet_ids  = module.networking.private_subnets
    database_subnet_ids = module.networking.database_subnets

    enable_eks = var.enable_eks

    cluster_name = var.enable_eks ? module.eks[0].cluster_name : null

    oidc_provider_arn = var.enable_eks ? module.eks[0].oidc_provider_arn : null
    oidc_provider     = var.enable_eks ? module.eks[0].oidc_provider : null
  }
}