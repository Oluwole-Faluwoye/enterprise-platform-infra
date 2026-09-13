# =========================================================
# DATABASE REGISTRY VARIABLES
# =========================================================

variable "registered_databases" {

  description = "Databases already registered with the platform"

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

    owner_team = optional(string)

    credentials = optional(object({
      provider         = string
      secret_arn       = string
      secret_name      = string
      management_mode  = string
      rotation_enabled = bool
    }))

  }))

  default = {}
}


variable "created_databases" {

  description = "Database catalog entries produced by the Database Golden Path during the current provisioning run"

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

    owner_team = optional(string)

    credentials = optional(object({
      provider         = string
      secret_arn       = string
      secret_name      = string
      management_mode  = string
      rotation_enabled = bool
    }))

  }))

  default = {}
}

