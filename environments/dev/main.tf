data "terraform_remote_state" "bootstrap" {

  backend = "s3"

  config = {
    bucket = "enterprise-platform-tf-state-761018849945"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

module "eks" {

  source = "../../modules/eks"

  count = var.enable_eks ? 1 : 0

  vpc_id = data.terraform_remote_state.bootstrap.outputs.vpc_id

  subnet_ids = data.terraform_remote_state.bootstrap.outputs.private_subnets

  jenkins_role_arn = data.terraform_remote_state.bootstrap.outputs.jenkins_role_arn

  terraform_role_arn = data.terraform_remote_state.bootstrap.outputs.terraform_deployer_role_arn

  allowed_k8s_api_cidrs = var.allowed_k8s_api_cidrs
}

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

module "secrets_manager" {

  source = "../../modules/secrets-manager"

  project = var.project_name

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

  project = var.project_name

  environment = var.environment

  oidc_provider_arn = module.eks[0].oidc_provider_arn

  oidc_provider = module.eks[0].oidc_provider

  secret_arns = module.secrets_manager.secret_arns

  hosted_zone_id = module.route53.hosted_zone_id

  external_dns_namespace       = var.external_dns_namespace
  
  external_dns_service_account = var.external_dns_service_account

}

module "route53" {

  source = "../../modules/route53"

  project = var.project_name

  environment = var.environment

  domain_name = var.domain_name

}

module "acm" {

  source = "../../modules/acm"

  project = var.project_name

  environment = var.environment

  domain_name = var.domain_name

  hosted_zone_id = module.route53.hosted_zone_id

}