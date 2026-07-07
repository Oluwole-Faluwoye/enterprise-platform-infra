resource "aws_iam_policy" "external_dns" {

  name = "${var.project}-${var.environment}-external-dns"

  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {
        Effect = "Allow"

        Action = [
          "route53:ChangeResourceRecordSets"
        ]

        Resource = [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
      },

      {
        Effect = "Allow"

        Action = [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]

        Resource = ["*"]
      }

    ]

  })

  tags = local.common_tags

}

resource "aws_iam_role_policy_attachment" "external_dns" {

  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn

}