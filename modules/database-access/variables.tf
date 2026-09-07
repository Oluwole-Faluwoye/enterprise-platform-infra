variable "project" {
  description = "Platform project name"
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

variable "access_requests" {
  type = map(object({
    service_name      = string
    team              = string
    namespace         = string
    database_name     = string
    mode              = string
    action            = string
    access            = string
    approval_required = bool
  }))
}

variable "database_catalog" {
  description = "Authoritative database catalog"

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