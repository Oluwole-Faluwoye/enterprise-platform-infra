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

  }))

  default = {}

}