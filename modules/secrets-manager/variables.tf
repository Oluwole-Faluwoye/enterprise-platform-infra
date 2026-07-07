variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "secrets" {

  description = "Secrets to create"

  type = map(object({

    description = string

  }))
}