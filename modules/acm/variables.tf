variable "project" {

  type = string

}

variable "environment" {

  type = string

}

variable "domain_name" {

  description = "Root domain"

  type = string

}

variable "hosted_zone_id" {

  description = "Route53 Hosted Zone ID"

  type = string

}