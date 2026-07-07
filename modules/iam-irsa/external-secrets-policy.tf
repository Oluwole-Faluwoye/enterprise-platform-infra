resource "aws_iam_policy" "external_secrets" {

  name = "enterprise-platform-external-secrets"

  description = "Allows External Secrets Operator to read AWS Secrets Manager."

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Sid = "SecretsManagerRead"

        Effect = "Allow"

        Action = [

          "secretsmanager:GetSecretValue",

          "secretsmanager:DescribeSecret",

          "secretsmanager:ListSecretVersionIds"

        ]

        Resource = values(var.secret_arns)

      }

    ]

  })

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "external_secrets" {

  role = aws_iam_role.external_secrets.name

  policy_arn = aws_iam_policy.external_secrets.arn

}