check "migration_secret_resolution_exists" {
  assert {
    condition = alltrue([
      for service_name, identity in local.migration_identities :
      identity.database_secret_arn != ""
    ])

    error_message = "Every migration workload must have a resolved database secret ARN."
  }
}

data "aws_iam_policy_document" "migration_assume_role" {
  for_each = local.migration_identities

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

resource "aws_iam_role" "migration" {
  for_each = local.migration_identities

  name = each.value.iam_role_name

  assume_role_policy = data.aws_iam_policy_document.migration_assume_role[
    each.key
  ].json

  tags = {
    Project     = var.project
    Environment = var.environment
    Service     = each.value.service_name
    ManagedBy   = "migration-workload-identity"
    Terraform   = "true"
  }
}

data "aws_iam_policy_document" "migration_access" {
  for_each = local.migration_identities

  statement {
    sid    = "ReadDatabaseCredential"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      each.value.database_secret_arn
    ]
  }

  statement {
    sid    = "ReadMigrationArtifacts"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      for bucket_arn in var.artifact_bucket_arns :
      "${bucket_arn}/${each.value.service_name}/migrations/*"
    ]
  }
}

resource "aws_iam_role_policy" "migration_access" {
  for_each = local.migration_identities

  name = "${each.value.service_name}-migration-access"

  role = aws_iam_role.migration[each.key].id

  policy = data.aws_iam_policy_document.migration_access[
    each.key
  ].json
}
