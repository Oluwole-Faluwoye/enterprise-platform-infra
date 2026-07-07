output "hosted_zone_id" {

  description = "Hosted Zone ID"

  value = aws_route53_zone.this.zone_id

}

output "hosted_zone_name_servers" {

  description = "Route53 Name Servers"

  value = aws_route53_zone.this.name_servers

}

output "hosted_zone_name" {

  description = "Hosted Zone Name"

  value = aws_route53_zone.this.name

}