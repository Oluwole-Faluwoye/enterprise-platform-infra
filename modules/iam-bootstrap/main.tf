resource "aws_iam_role" "terraform_deployer" {

  name = "enterprise-platform-terraform-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          AWS = [

            var.admin_user_arn,

            var.jenkins_role_arn

          ]

        }

        Action = "sts:AssumeRole"

      }

    ]

  })

  tags = {

    Terraform = "true"

  }

}

resource "aws_iam_role_policy_attachment" "administrator_access" {

  role = aws_iam_role.terraform_deployer.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"

}