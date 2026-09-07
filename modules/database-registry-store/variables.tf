# =========================================================
# DATABASE REGISTRY STORE VARIABLES
# =========================================================

variable "project" {

  description = "Platform project name"

  type = string

}


variable "environment" {

  description = "Environment owning this registry store"

  type = string

  validation {

    condition = contains(
      ["bootstrap"],
      var.environment
    )

    error_message = "Database registry store must be deployed by bootstrap."

  }

}


variable "table_name" {

  description = "DynamoDB table name for the platform database registry"

  type = string

}


variable "billing_mode" {

  description = "DynamoDB billing mode"

  type = string

  default = "PAY_PER_REQUEST"

  validation {

    condition = var.billing_mode == "PAY_PER_REQUEST"

    error_message = "The database registry currently supports PAY_PER_REQUEST only."

  }

}