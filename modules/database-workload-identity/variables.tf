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

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  type        = string
}

variable "oidc_provider" {
  description = "EKS OIDC provider URL"
  type        = string
}

variable "secret_resolutions" {
  description = "Resolved database secret mappings for workloads"

  type = map(object({
    service_name      = string
    team              = string
    namespace         = string
    database_name     = string
    access            = string
    mode              = string
    approval_required = bool

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
      status             = string
      management_mode   = string
    })

    secret = object({
      secret_arn      = string
      secret_name     = string
      management_mode = string
    })

    secret_exists = bool
  }))

  default = {}
}

variable "approved_services" {
  description = "Database workloads explicitly approved for access"

  type    = set(string)
  default = []
}

