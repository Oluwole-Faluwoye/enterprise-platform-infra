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

variable "migration_requests" {
  description = "Services requesting database migration capability"

  type = map(object({
    enabled = bool
    engine  = string
  }))

  default = {}
}

variable "service_namespaces" {
  description = "Kubernetes namespace for each service"
  type        = map(string)
  default     = {}
}

variable "database_secret_arns" {
  description = "Resolved database credential secret ARN by service"
  type        = map(string)
  default     = {}
}

variable "artifact_bucket_arns" {
  description = "S3 artifact bucket ARNs accessible by migration workloads"
  type        = list(string)
  default     = []
}
