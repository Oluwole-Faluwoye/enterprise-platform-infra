variable "project" {

  description = "Project name"

  type = string

}

variable "environment" {

  description = "Deployment environment"

  type = string

}

variable "oidc_provider_arn" {

  description = "OIDC Provider ARN"

  type = string

}

variable "oidc_provider" {

  description = "OIDC Provider URL"

  type = string

}

variable "namespace" {

  description = "Kubernetes namespace"

  type = string

  default = "external-secrets"

}

variable "service_account_name" {

  description = "ServiceAccount name"

  type = string

  default = "external-secrets"

}

variable "secret_arns" {

  description = "Secrets Manager ARNs"

  type = map(string)

}

# =========================================================
# AWS LOAD BALANCER CONTROLLER
# =========================================================

variable "aws_load_balancer_namespace" {

  description = "Namespace for the AWS Load Balancer Controller"

  type = string

  default = "kube-system"

}

variable "aws_load_balancer_service_account" {

  description = "Service Account used by the AWS Load Balancer Controller"

  type = string

  default = "aws-load-balancer-controller"

}

variable "external_dns_namespace" {

  description = "Namespace where ExternalDNS is deployed"

  type = string

  default = "external-dns"

}

variable "external_dns_service_account" {

  description = "ExternalDNS Service Account"

  type = string

  default = "external-dns"

}

variable "hosted_zone_id" {

  description = "Route53 Hosted Zone ID"

  type = string

}