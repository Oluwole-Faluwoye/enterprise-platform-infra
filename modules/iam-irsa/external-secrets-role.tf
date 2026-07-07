resource "aws_iam_role" "external_secrets" {

  name = "${var.project}-${var.environment}-external-secrets-role"

  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json

  tags = local.common_tags

}