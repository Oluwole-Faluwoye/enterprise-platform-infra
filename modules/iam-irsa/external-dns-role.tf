data "aws_iam_policy_document" "external_dns_assume" {

  statement {

    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {

      type = "Federated"

      identifiers = [
        var.oidc_provider_arn
      ]

    }

    condition {

      test = "StringEquals"

      variable = "${replace(var.oidc_provider, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.external_dns_namespace}:${var.external_dns_service_account}"
      ]

    }

  }

}

resource "aws_iam_role" "external_dns" {

  name = "${var.project}-${var.environment}-external-dns"

  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json

  tags = local.common_tags

}