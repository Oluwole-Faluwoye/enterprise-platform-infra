variable "project" {
  description = "Platform project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "application_name" {
  description = "Logical application/service name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,62}$", var.application_name))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID where the application security group will be created"
  type        = string
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}