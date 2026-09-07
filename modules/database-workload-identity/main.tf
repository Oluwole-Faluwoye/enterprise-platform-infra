check "workload_secret_resolution_exists" {
  assert {
    condition = alltrue([
      for service_name, workload in local.workload_identities :
      workload.secret_arn != ""
    ])

    error_message = "Every database workload identity must have a resolved secret ARN."
  }
}

data "aws_iam_policy_document" "workload_assume_role" {
  for_each = local.workload_identities

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${each.value.namespace}:${each.value.service_account_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "workload" {
  for_each = local.workload_identities

  name = each.value.iam_role_name

  assume_role_policy = data.aws_iam_policy_document.workload_assume_role[
    each.key
  ].json

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = each.value.service_name
    ManagedBy   = "workload-identity-golden-path"
    Terraform   = "true"
  }
}

data "aws_iam_policy_document" "secret_access" {
  for_each = local.workload_identities

  statement {
    sid    = "ReadDatabaseCredential"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      each.value.secret_arn
    ]
  }
}

resource "aws_iam_role_policy" "secret_access" {
  for_each = local.workload_identities

  name = "${each.value.service_name}-database-secret-access"

  role = aws_iam_role.workload[each.key].id

  policy = data.aws_iam_policy_document.secret_access[
    each.key
  ].json
}