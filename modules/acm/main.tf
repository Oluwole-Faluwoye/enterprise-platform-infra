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

resource "aws_route53_record" "validation" {

  for_each = {

    for dvo in aws_acm_certificate.platform.domain_validation_options :

    dvo.domain_name => {

      name   = dvo.resource_record_name

      record = dvo.resource_record_value

      type   = dvo.resource_record_type

    }

  }

  allow_overwrite = true

  zone_id = var.hosted_zone_id

  name = each.value.name

  type = each.value.type

  ttl = 60

  records = [

    each.value.record

  ]

}

resource "aws_acm_certificate_validation" "platform" {

  certificate_arn = aws_acm_certificate.platform.arn

  validation_record_fqdns = [

    for record in aws_route53_record.validation :

    record.fqdn

  ]

}