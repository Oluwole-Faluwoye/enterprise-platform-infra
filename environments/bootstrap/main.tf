# =========================================================
# BOOTSTRAP VPC
# =========================================================

module "vpc" {
  source = "../../modules/networking"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.azs

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  database_subnets = var.database_subnets

  enable_nat_gateway = var.enable_nat_gateway

  enable_kubernetes_tags = false
}


# ECR - Jenkins Image

module "jenkins_ecr" {

  count = var.enable_ecr ? 1 : 0

  source = "../../modules/ecr"

  name = var.jenkins_repo_name
}

# ECR - Application Images

module "app_ecr" {

  count = var.enable_ecr ? 1 : 0

  source = "../../modules/ecr"

  name = var.app_repo_name
}

# Jenkins EC2
module "jenkins" {

  count = var.enable_jenkins ? 1 : 0

  source = "../../modules/jenkins"

  subnet_id      = module.vpc.public_subnets[0]
  key_name       = var.key_name
  user_data_path = "${path.module}/setup.sh"
  vpc_id         = module.vpc.vpc_id

  allowed_jenkins_ssh_cidrs = var.allowed_jenkins_ssh_cidrs
}


# =========================================================
# IAM BOOTSTRAP
# =========================================================

module "iam_bootstrap" {

  count = var.enable_jenkins ? 1 : 0

  source = "../../modules/iam-bootstrap"

  admin_user_arn = var.admin_user_arn

  jenkins_role_arn = module.jenkins[0].jenkins_role_arn

}

# =========================================================
# DATABASE REGISTRY STORE
# =========================================================
#
# The database registry is platform foundation infrastructure.
#
# It belongs to bootstrap rather than an individual environment
# so that destroying DEV/STAGING/PROD does not destroy the
# authoritative registry.
# =========================================================

module "database_registry_store" {

  source = "../../modules/database-registry-store"

  project = "enterprise-platform"

  environment = "bootstrap"

  table_name = "enterprise-platform-database-registry"

}

# =========================================================
# Route 53 Root Route 53 ( This creates dreammyles.online)
# =========================================================
module "route53_root" {
  source = "../../modules/route53"

  project     = "enterprise-platform"
  environment = "bootstrap"

  domain_name = var.domain_name
}

# =================================================================
# Route 53 child Route 53 ( This creates dev.dreammyles.online)
# =================================================================

module "route53_dev" {
  source = "../../modules/route53"

  project     = "enterprise-platform"
  environment = "dev-dns"

  domain_name = var.dev_domain_name
}


# =============================================================================
# NS delegation : After the child zone exists, Route53 gives it name servers.
# =============================================================================

resource "aws_route53_record" "dev_delegation" {
  zone_id = module.route53_root.hosted_zone_id
  name    = var.dev_domain_name
  type    = "NS"
  ttl     = 300

  records = module.route53_dev.hosted_zone_name_servers
}