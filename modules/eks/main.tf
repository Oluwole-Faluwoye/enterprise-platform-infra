# =========================================================
# EKS MODULE
# =========================================================

module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name = "devops-cluster"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.allowed_k8s_api_cidrs

  enable_cluster_creator_admin_permissions = false

  cluster_addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    aws-ebs-csi-driver = {
      most_recent = true
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

      desired_size = 1
      max_size     = 2
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