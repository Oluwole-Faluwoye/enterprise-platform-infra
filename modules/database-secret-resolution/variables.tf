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

variable "access_decisions" {
  description = "Resolved database access decisions"
  type = map(object({
    service_name      = string
    database_name     = string
    team              = string
    namespace         = string
    mode              = string
    action            = string
    access            = string
    approval_required = bool
    database_exists   = bool

    database = object({
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
    })
  }))

  default = {}
}

variable "database_secret_registry" {
  description = "Registered Secrets Manager references for databases"
  type = map(object({
    secret_arn      = string
    secret_name     = string
    management_mode = string
  }))

  default = {}
}