# =========================================================
# EKS MODULE
# =========================================================

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.allowed_k8s_api_cidrs

  enable_cluster_creator_admin_permissions = false

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }

    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }

  # =========================================================
  # EKS ACCESS ENTRY FOR JENKINS EC2 ROLE
  # =========================================================

  access_entries = {

    jenkins_admin = {
      principal_arn = var.jenkins_role_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    terraform_admin = {
      principal_arn = var.terraform_role_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }


  # =========================================================
  # MANAGED NODE GROUPS
  # =========================================================


  eks_managed_node_groups = {

    devops_nodes = {

      name = "devops-nodes"

      desired_size = 3
      max_size     = 3
      min_size     = 1

      instance_types = ["t3.medium"]

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {
    Name        = "devops-nodes"
    Environment = "dev"
    Terraform   = "true"
  }
}