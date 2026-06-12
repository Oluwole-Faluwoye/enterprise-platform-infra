resource "aws_iam_role" "terraform_deployer" {

  name = "terraform-deployer-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          AWS = var.jenkins_role_arn
        }

        Action = "sts:AssumeRole"
      }
    ]

  })
}

resource "aws_iam_role_policy_attachment" "administrator_access" {

  role = aws_iam_role.terraform_deployer.name

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
