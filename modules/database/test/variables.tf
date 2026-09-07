variable "environment" {
  description = "Environment being tested"
  type        = string

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )

    error_message = "Environment must be one of: dev, staging, prod."
  }
}