
# =========================================================
# AWS Region retrieval automatic
# =========================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
# =========================================================
# AMAZON LINUX 2023 AMI
# =========================================================

data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# =========================================================
# SECURITY GROUP
# =========================================================

resource "aws_security_group" "jenkins_sg" {

  name = "jenkins-sg"

  vpc_id = var.vpc_id

  # SSH

  ingress {

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = var.allowed_jenkins_ssh_cidrs
  }

  # Jenkins

  ingress {

    from_port = 8080
    to_port   = 8080

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube

  ingress {

    from_port = 9000
    to_port   = 9000

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {

    Name = "jenkins-sg"
  }
}

# =========================================================
# IAM ROLE
# =========================================================

resource "aws_iam_role" "jenkins_role" {

  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

# =========================================================
# SECRETS MANAGER ACCESS
# =========================================================

resource "aws_iam_role_policy" "jenkins_secrets_manager" {

  name = "jenkins-secrets-manager"

  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Sid = "ReadGitOpsSecret"

        Effect = "Allow"

        Action = [

          "secretsmanager:GetSecretValue",

          "secretsmanager:DescribeSecret"

        ]

        Resource = [

          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:argocd/gitops/private-key*"

        ]
      }
    ]
  })
}

# =========================================================
# SSM POLICY
# =========================================================

resource "aws_iam_role_policy_attachment" "ssm" {

  role = aws_iam_role.jenkins_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# =========================================================
# ADMINISTRATOR ACCESS (TEMPORARY)
# =========================================================

resource "aws_iam_role_policy_attachment" "admin_access" {

  role = aws_iam_role.jenkins_role.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


# =========================================================
# INLINE POLICY
# =========================================================

resource "aws_iam_role_policy" "jenkins_inline_policy" {

  name = "jenkins-devops-policy"

  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      # ==================================================
      # TERRAFORM STATE S3
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = [
          "arn:aws:s3:::enterprise-platform-tf-state-761018849945"
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::enterprise-platform-tf-state-761018849945/*"
        ]
      },

      # ==================================================
      # TERRAFORM STATE LOCKING
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]

        Resource = [
          "arn:aws:dynamodb:us-east-1:761018849945:table/terraform-locks"
        ]
      },

      # ==================================================
      # ECR
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = "*"
      },

      # ==================================================
      # EKS READ ONLY
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:ListClusters",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi"
        ]

        Resource = "*"
      },

      # ==================================================
      # EC2 READ ONLY
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcs",
          "ec2:DescribeVolumes",
          "ec2:DescribeAvailabilityZones"
        ]

        Resource = "*"
      },

      # ==================================================
      # IAM PASS ROLE
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "*"
      },

      # ==================================================
      # CLOUDWATCH
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]

        Resource = "*"
      },

      # ==================================================
      # FUTURE ASSUME ROLE
      # ==================================================

      {
        Effect = "Allow"

        Action = [
          "sts:AssumeRole"
        ]

        Resource = "*"
      }
    ]
  })
}

# =========================================================
# INSTANCE PROFILE
# =========================================================

resource "aws_iam_instance_profile" "jenkins_profile" {

  role = aws_iam_role.jenkins_role.name
}

# =========================================================
# EC2 INSTANCE
# =========================================================

resource "aws_instance" "jenkins" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t3.medium"

  subnet_id = var.subnet_id

  key_name = var.key_name

  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  user_data = file(var.user_data_path)

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"
  }

  root_block_device {

    volume_size = 30

    volume_type = "gp3"

    encrypted = true

    delete_on_termination = true
  }

  lifecycle {

    ignore_changes = [
      ami,
      user_data
    ]
  }

  tags = {

    Name = "Jenkins-Server"
  }
}

# =========================================================
# DEDICATED PERSISTENT EBS VOLUME
# =========================================================

data "aws_subnet" "jenkins" {
  id = var.subnet_id
}

resource "aws_ebs_volume" "jenkins_data" {

  availability_zone = data.aws_subnet.jenkins.availability_zone

  size = 30

  type = "gp3"

  encrypted = true

  lifecycle {

    prevent_destroy = true
  }

  tags = {

    Name = "jenkins-data-volume"
    Persistent = "true"
  }
}

# =========================================================
# ATTACH EBS TO EC2
# =========================================================

resource "aws_volume_attachment" "jenkins_attach" {

  device_name = "/dev/xvdf"

  volume_id = aws_ebs_volume.jenkins_data.id

  instance_id = aws_instance.jenkins.id

  force_detach = true
}

# =========================================================
# CLOUDWATCH LOG GROUP
# =========================================================

resource "aws_cloudwatch_log_group" "jenkins" {

  name = "/platform/jenkins"

  retention_in_days = 30

  tags = {

    Name = "jenkins-log-group"
  }
}