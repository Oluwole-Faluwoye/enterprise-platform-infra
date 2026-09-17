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

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.this.id

  description = "Allow DNS queries to the VPC resolver"

  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.this.id

  description = "Allow DNS TCP queries to the VPC resolver"

  ip_protocol = "tcp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id

  description = "Allow HTTPS access to AWS services and external endpoints"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}