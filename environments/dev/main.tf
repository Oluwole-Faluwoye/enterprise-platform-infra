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

  home_ip = var.home_ip
}


# IAM (cost controlled)
module "iam" {

  count = var.enable_jenkins ? 1 : 0

  source = "../../modules/iam"

  jenkins_role_arn = module.jenkins[0].jenkins_role_arn
}

# EKS (cost controlled)
module "eks" {

  source = "../../modules/eks"

  count = var.enable_eks ? 1 : 0

  enable_jenkins = var.enable_jenkins

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group_rule" "jenkins_to_eks" {

  count = var.enable_eks && var.enable_jenkins ? 1 : 0

  type = "ingress"

  from_port = 443
  to_port   = 443

  protocol = "tcp"

  security_group_id = module.eks[0].cluster_security_group_id

  source_security_group_id = module.jenkins[0].security_group_id

  description = "Allow Jenkins to access EKS API"
}