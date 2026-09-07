# =========================================================
# BOOTSTRAP REMOTE STATE
# =========================================================
#
# Bootstrap remains the source of shared foundation resources.
#
# DEV does NOT consume Bootstrap networking.
# =========================================================

data "terraform_remote_state" "bootstrap" {
  backend = "s3"

  config = {
    bucket = "enterprise-platform-tf-state-761018849945"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

# =========================================================
# DEV NETWORKING
# =========================================================
#
# DEV owns its own VPC and subnet infrastructure.
# =========================================================

module "networking" {
  source = "../../modules/networking"

  name = "${var.project_name}-${var.environment}"

  cidr = var.vpc_cidr

  azs = var.azs

  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  enable_nat_gateway = var.enable_nat_gateway

  environment = var.environment

  cluster_name = var.cluster_name

  enable_kubernetes_tags = true
}

# =========================================================
# DEV EKS
# =========================================================
#
# EKS is owned by DEV and runs inside the DEV VPC.
#
# Shared IAM dependencies still come from Bootstrap.
# =========================================================

module "eks" {
  source = "../../modules/eks"

  count = var.enable_eks ? 1 : 0

  cluster_name = var.cluster_name

  vpc_id = module.networking.vpc_id

  kubernetes_version = "1.33"

  subnet_ids = module.networking.private_subnets

  jenkins_role_arn = data.terraform_remote_state.bootstrap.outputs.jenkins_role_arn

  terraform_role_arn = data.terraform_remote_state.bootstrap.outputs.terraform_deployer_role_arn

  allowed_k8s_api_cidrs = var.allowed_k8s_api_cidrs
}

# =========================================================
# JENKINS → EKS API
# =========================================================
#
# Jenkins is still a Bootstrap resource.
#
# NOTE:
# This SG relationship only works if Jenkins and EKS have
# network reachability. See migration note below.
# =========================================================

resource "aws_security_group_rule" "jenkins_to_eks" {
  count = var.enable_eks ? 1 : 0

  type = "ingress"

  from_port = 443
  to_port   = 443

  protocol = "tcp"

  security_group_id = module.eks[0].cluster_security_group_id

  source_security_group_id = data.terraform_remote_state.bootstrap.outputs.jenkins_security_group_id

  description = "Allow Jenkins to access EKS API"
}

# =========================================================
# SECRETS MANAGER
# =========================================================

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project     = var.project_name
  environment = var.environment

  secrets = {
    "grafana/admin" = {
      description = "Grafana Administrator"
    }

    "auth-service" = {
      description = "Auth Service"
    }

    "alertmanager" = {
      description = "Alertmanager SMTP"
    }
  }
}

# =========================================================
# IAM IRSA
# =========================================================

module "iam_irsa" {
  count = var.enable_eks ? 1 : 0

  source = "../../modules/iam-irsa"

  project     = var.project_name
  environment = var.environment

  oidc_provider_arn = module.eks[0].oidc_provider_arn
  oidc_provider     = module.eks[0].oidc_provider

  secret_arns = module.secrets_manager.secret_arns

  hosted_zone_id = module.route53.hosted_zone_id

  external_dns_namespace = var.external_dns_namespace

  external_dns_service_account = var.external_dns_service_account
}

# =========================================================
# ROUTE53
# =========================================================

module "route53" {
  source = "../../modules/route53"

  project     = var.project_name
  environment = var.environment

  domain_name = var.domain_name
}

# =========================================================
# ACM
# =========================================================

module "acm" {
  source = "../../modules/acm"

  project     = var.project_name
  environment = var.environment

  domain_name = var.domain_name

  hosted_zone_id = module.route53.hosted_zone_id
}

# =========================================================
# PLATFORM PROVISIONING
# =========================================================
#
# The DEV environment supplies infrastructure context.
# Platform provisioning remains environment-agnostic.
# =========================================================

module "provisioning" {
  source = "../../platform/provisioning"

  project     = var.project_name
  environment = var.environment

  environment_context = {
    vpc_id              = module.networking.vpc_id
    private_subnet_ids  = module.networking.private_subnets
    database_subnet_ids = module.networking.database_subnets

    enable_eks = var.enable_eks

    cluster_name = var.enable_eks ? module.eks[0].cluster_name : null

    oidc_provider_arn = var.enable_eks ? module.eks[0].oidc_provider_arn : null
    oidc_provider     = var.enable_eks ? module.eks[0].oidc_provider : null
  }

  services = var.services

  database_registry        = var.database_registry
  database_secret_registry = var.database_secret_registry

  approved_services = var.approved_services
}