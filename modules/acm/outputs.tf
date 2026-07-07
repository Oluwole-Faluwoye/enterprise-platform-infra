output "certificate_arn" {

  description = "ACM Certificate ARN"

  value = aws_acm_certificate.platform.arn

}

output "certificate_domain" {

  value = aws_acm_certificate.platform.domain_name

}