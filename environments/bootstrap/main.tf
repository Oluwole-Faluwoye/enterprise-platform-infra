# VPC
module "vpc" {
  source = "../../modules/networking"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.azs

  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
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