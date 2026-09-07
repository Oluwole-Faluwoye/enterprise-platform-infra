variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )

    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the database subnet group"
  type        = list(string)

  validation {
    condition = length(var.private_subnet_ids) >= 2

    error_message = "At least two private subnets are required for the database."
  }
}

variable "database_name" {
  description = "Initial database name"
  type        = string

  validation {
    condition = can(
      regex(
        "^[a-z][a-z0-9_]{0,62}$",
        var.database_name
      )
    )

    error_message = "Database name must start with a lowercase letter and contain only lowercase letters, numbers, and underscores."
  }
}

variable "engine" {
  description = "Logical database engine requested by the developer"
  type        = string

  default = "postgres"

  validation {
    condition = contains(
      [
        "postgres",
        "mysql",
        "aurora-postgres",
        "aurora-mysql",
        "mongodb"
      ],
      var.engine
    )

    error_message = "Supported engines are: postgres, mysql, aurora-postgres, aurora-mysql, mongodb."
  }
}

variable "size" {
  description = "Logical database size selected by the developer"
  type        = string

  validation {
    condition = contains(
      [
        "small",
        "medium",
        "large",
        "xlarge"
      ],
      var.size
    )

    error_message = "Database size must be one of: small, medium, large, xlarge."
  }
}

# =========================================================
# INTERNAL PLATFORM DEPENDENCY
# =========================================================

variable "application_name" {
  description = "Application workload that consumes this database"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.application_name))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "application_security_group_id" {
  description = "Platform-resolved security group ID for the consuming application"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-zA-Z0-9]+$", var.application_security_group_id))
    error_message = "application_security_group_id must be a valid AWS security group ID."
  }
}

# =========================================================
# OPTIONAL PLATFORM OVERRIDE
# =========================================================

variable "backup_retention_period" {
  description = "Optional backup retention override. Environment defaults apply when omitted."
  type        = number
  default     = null

  validation {
    condition = (
      var.backup_retention_period == null ||
      (
        var.backup_retention_period >= 1 &&
        var.backup_retention_period <= 35
      )
    )

    error_message = "Backup retention must be between 1 and 35 days."
  }
}