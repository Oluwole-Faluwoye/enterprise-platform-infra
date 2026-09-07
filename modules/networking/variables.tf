variable "name" {
  description = "Name of the VPC and associated networking resources"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The VPC CIDR block must be valid."
  }
}

variable "azs" {
  description = "Availability Zones used by the VPC"
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway resources"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment used for resource tagging"
  type        = string
  default     = null

  validation {
    condition = var.environment == null || contains(
      ["dev", "staging", "prod"],
      var.environment
    )
    error_message = "Environment must be one of: dev, staging, prod, or null."
  }
}

variable "cluster_name" {
  description = "EKS cluster name used for Kubernetes subnet discovery tags"
  type        = string
  default     = null
}

variable "enable_kubernetes_tags" {
  description = "Whether to apply Kubernetes subnet discovery tags"
  type        = bool
  default     = false
}