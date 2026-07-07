locals {

  common_tags = {

    Project     = var.project
    Environment = var.environment
    Terraform   = "true"

  }

}

resource "aws_secretsmanager_secret" "this" {

  for_each = var.secrets

  name = "${var.project}/${var.environment}/${each.key}"

  description = each.value.description

  recovery_window_in_days = 7

  tags = local.common_tags

}