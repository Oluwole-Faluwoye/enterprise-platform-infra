resource "aws_iam_role" "aws_load_balancer_controller" {

  name = "${var.project}-${var.environment}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Effect = "Allow"

        Principal = {

          Federated = var.oidc_provider_arn

        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {

          StringEquals = {

            (format(
              "%s:sub",
              replace(var.oidc_provider, "https://", "")
            )) = "system:serviceaccount:${var.aws_load_balancer_namespace}:${var.aws_load_balancer_service_account}"

          }

        }

      }

    ]

  })

  tags = local.common_tags
}