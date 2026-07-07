output "external_secrets_role_arn" {

  description = "IRSA Role ARN"

  value = aws_iam_role.external_secrets.arn

}

output "external_secrets_policy_arn" {

  description = "External Secrets IAM Policy ARN"

  value = aws_iam_policy.external_secrets.arn

}

output "aws_load_balancer_controller_role_arn" {

  description = "IAM Role ARN for AWS Load Balancer Controller"

  value = aws_iam_role.aws_load_balancer_controller.arn

}

output "aws_load_balancer_controller_policy_arn" {

  description = "IAM Policy ARN for AWS Load Balancer Controller"

  value = aws_iam_policy.aws_load_balancer_controller.arn

}

output "external_dns_role_arn" {

  description = "ExternalDNS IAM Role"

  value = aws_iam_role.external_dns.arn

}