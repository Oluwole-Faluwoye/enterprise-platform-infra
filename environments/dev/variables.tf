variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_eks" {
  description = "Toggle EKS creation"
  type        = bool
  default     = false
}

# =========================================================
# ALLOWED KUBERNETES API CIDRS
# =========================================================

variable "allowed_k8s_api_cidrs" {
  description = "CIDRs allowed to access the EKS API endpoint"
  type        = list(string)
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "admin_user_arn" {
  type = string
}

# =========================================================
# ROUTE 53 RESOURCE VARIABLE (DOMAIN NAME)
# =========================================================

variable "domain_name" {

  description = "Platform domain"

  type = string

}

variable "external_dns_namespace" {

  description = "Namespace where ExternalDNS is deployed"

  type = string

  default = "kube-system"
}

variable "external_dns_service_account" {

  description = "ExternalDNS Service Account"

  type = string

  default = "external-dns"

}