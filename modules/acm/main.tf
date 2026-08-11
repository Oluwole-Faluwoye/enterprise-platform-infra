resource "aws_acm_certificate" "platform" {

  domain_name = "*.dev.${var.domain_name}"

  subject_alternative_names = [
    "dev.${var.domain_name}"
  ]

  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

locals {
  certificate_domains = [
    "*.dev.${var.domain_name}",
    "dev.${var.domain_name}"
  ]
}

resource "aws_route53_record" "validation" {

  for_each = toset(local.certificate_domains)

  allow_overwrite = true

  zone_id = var.hosted_zone_id

  name = one([
    for dvo in aws_acm_certificate.platform.domain_validation_options :
    dvo.resource_record_name
    if dvo.domain_name == each.key
  ])

  type = one([
    for dvo in aws_acm_certificate.platform.domain_validation_options :
    dvo.resource_record_type
    if dvo.domain_name == each.key
  ])

  ttl = 60

  records = [
    one([
      for dvo in aws_acm_certificate.platform.domain_validation_options :
      dvo.resource_record_value
      if dvo.domain_name == each.key
    ])
  ]
}

resource "aws_acm_certificate_validation" "platform" {

  certificate_arn = aws_acm_certificate.platform.arn

  validation_record_fqdns = [
    for record in aws_route53_record.validation :
    record.fqdn
  ]
}