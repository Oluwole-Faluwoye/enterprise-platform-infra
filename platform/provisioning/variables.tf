# =========================================================
# PLATFORM PROVISIONING VARIABLES
# =========================================================


variable "aws_region" {

  description = "AWS region where platform infrastructure is deployed"

  type = string

  default = "us-east-1"

}


variable "project" {

  description = "Platform project name"

  type = string

}


variable "environment" {

  description = "Deployment environment"

  type = string

  validation {

    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )

    error_message = "Environment must be one of: dev, staging, prod."

  }

}

# =========================================================
# ENVIRONMENT INFRASTRUCTURE CONTEXT
# =========================================================

variable "environment_context" {
  description = "Infrastructure context supplied by the target environment"

  type = object({
    enable_eks                = bool
    vpc_id                    = string
    private_subnet_ids        = list(string)
    database_subnet_ids       = list(string)
    cluster_name              = optional(string)
    jenkins_security_group_id = optional(string)
    oidc_provider_arn         = optional(string)
    oidc_provider             = optional(string)
  })
}


# =========================================================
# SERVICE CONTRACTS
# =========================================================
#
# These are normally supplied by the platform workflow after
# Backstage/GitOps contract generation and peer review.
#
# The provisioning layer passes them to the resolver.
# =========================================================


variable "services" {

  description = "Developer service contracts submitted to the platform"

  type = map(object({

    runtime = string

    team = string

    persistence = object({

      enabled = bool

      mode = string

      engine = optional(string)

      size = optional(string)

      database_name = optional(string)

      access = optional(string)

    })

  }))

}

# =========================================================
# DATABASE REGISTRY
# =========================================================

variable "database_registry" {

  description = "Platform-owned registry of databases available for application access"

  type = map(object({

    logical_name = string

    environment = string

    engine = string

    resource_type = string

    resource_id = string

    port = number

    endpoint = optional(string)

    reader_endpoint = optional(string)

    security_group_id = string

    subnet_group_name = optional(string)

    status = string

    management_mode = string

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