
module "eks" {

  source = "terraform-aws-modules/eks/aws"

  version = "~> 20.0"

  cluster_name = "devops-cluster"

  vpc_id = var.vpc_id

  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  # =========================================================
  # EKS ACCESS ENTRY FOR JENKINS EC2 ROLE
  # =========================================================

  access_entries = var.enable_jenkins ? {

    jenkins_admin = {

      principal_arn = "arn:aws:iam::761018849945:role/jenkins-ec2-role"

      policy_associations = {

        admin = {

          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }

  } : {}




  # =========================================================
  # MANAGED NODE GROUPS
  # =========================================================

  eks_managed_node_groups = {

    default = {

      desired_size = 1

      max_size = 2

      min_size = 1

      instance_types = ["t3.medium"]

      capacity_type = "ON_DEMAND"
    }
  }

  tags = {

    Environment = "dev"

    Terraform = "true"
  }
}