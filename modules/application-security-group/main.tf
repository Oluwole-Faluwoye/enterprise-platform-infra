resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-${var.application_name}"
  description = "Application security group for ${var.application_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-${var.application_name}"
      Project     = var.project
      Environment = var.environment
      Application = var.application_name
      ManagedBy   = "application-golden-path"
      Terraform   = "true"
    }
  )
}