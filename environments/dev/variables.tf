variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# =========================================================
# ENVIRONMENT LIFECYCLE
# =========================================================

variable "enable_eks" {
  description = "Whether EKS should exist in this environment"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Whether NAT Gateway resources should exist"
  type        = bool
  default     = false
}

# =========================================================
# NETWORKING
# =========================================================

variable "vpc_cidr" {
  description = "CIDR block for the environment VPC"
  type        = string
}

variable "azs" {
  description = "Availability Zones for the environment"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "database_subnets" {
  description = "Database subnet CIDRs"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

# =========================================================
# EKS
# =========================================================

variable "allowed_k8s_api_cidrs" {
  description = "CIDRs allowed to access the EKS API endpoint"
  type        = list(string)
}

# =========================================================
# PLATFORM
# =========================================================

variable "project_name" {
  type = string
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "admin_user_arn" {
  type = string
}

variable "domain_name" {
  description = "Platform domain"
  type        = string
}

variable "external_dns_namespace" {
  description = "Namespace where ExternalDNS is deployed"
  type        = string
  default     = "kube-system"
}

variable "external_dns_service_account" {
  description = "ExternalDNS Service Account"
  type        = string
  default     = "external-dns"
}

variable "services" {
  description = "Developer service declarations consumed by platform provisioning"

  type = map(object({
    runtime = string
    team    = string

    persistence = object({
      enabled       = bool
      mode          = optional(string, "none")
      engine        = optional(string)
      size          = optional(string)
      database_name = optional(string)
      access        = optional(string)
    })
  }))

  default = {}
}

variable "database_registry" {
  description = "Registered databases available to platform access workflows"

  type = map(object({
    logical_name      = string
    environment       = string
    engine            = string
    resource_type     = string
    resource_id       = string
    port              = number
    endpoint          = optional(string)
    reader_endpoint   = optional(string)
    security_group_id = string
    subnet_group_name = optional(string)
    status            = string
    management_mode   = string
  }))

  default = {}
}

variable "database_secret_registry" {
  description = "Registered credential secret references for databases"

  type = map(object({
    secret_arn      = string
    secret_name     = string
    management_mode = string
  }))

  default = {}
}

variable "approved_services" {
  description = "Database workloads explicitly approved by the platform"

  type    = set(string)
  default = []
}