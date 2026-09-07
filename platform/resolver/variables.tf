# =========================================================
# PLATFORM RESOLVER VARIABLES
# =========================================================

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
# SERVICE CONTRACTS
# =========================================================
#
# Developers describe application intent.
#
# Developers do NOT provide:
#
#   - VPC IDs
#   - subnet IDs
#   - security group IDs
#   - RDS identifiers
#   - IAM role ARNs
#   - AWS resource names
#
# The platform resolves those dependencies.
# =========================================================

variable "services" {

  description = "Application service contracts consumed by the platform resolver"

  type = map(object({

    runtime = string

    team = string

    persistence = object({

      enabled = bool

      # ===================================================
      # Persistence mode
      #
      # none
      # new
      # existing
      # shared
      # temporary
      # ===================================================

      mode = optional(
        string,
        "none"
      )

      # ===================================================
      # Database engine
      #
      # Used by:
      #
      #   new
      #   temporary
      #
      # ===================================================

      engine = optional(string)

      # ===================================================
      # Database size
      #
      # Used by:
      #
      #   new
      #   temporary
      #
      # ===================================================

      size = optional(string)

      # ===================================================
      # Logical database reference
      #
      # Used by:
      #
      #   existing
      #   shared
      #
      # ===================================================

      database_name = optional(string)

      # ===================================================
      # Data access level
      #
      # read
      # read_write
      #
      # Used by:
      #
      #   existing
      #   shared
      #
      # The platform determines whether approval is needed.
      # ===================================================

      access = optional(string)

    })

  }))

  # =======================================================
  # TEAM / NAMESPACE VALIDATION
  # =======================================================
  #
  # Team is used by the platform as the Kubernetes
  # namespace boundary.
  #
  # Developers provide the team.
  # The platform derives the namespace.
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      can(regex(
        "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$",
        service.team
      ))
      &&
      length(service.team) <= 63

    ])

    error_message = "Team must be a valid Kubernetes namespace-compatible name: lowercase letters, numbers, and hyphens, with a maximum length of 63 characters."

  }


  # =======================================================
  # PERSISTENCE MODE VALIDATION
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      contains(
        [
          "none",
          "new",
          "existing",
          "shared",
          "temporary"
        ],
        service.persistence.mode
      )

    ])

    error_message = "Persistence mode must be one of: none, new, existing, shared, temporary."

  }


  # =======================================================
  # ENABLED / MODE CONSISTENCY
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      service.persistence.enabled
      ? service.persistence.mode != "none"
      : service.persistence.mode == "none"

    ])

    error_message = "A service with persistence disabled must use mode 'none'."

  }


  # =======================================================
  # ACCESS VALIDATION
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      service.persistence.access == null
      ?
      true
      :
      contains(
        [
          "read",
          "read_write"
        ],
        service.persistence.access
      )

    ])

    error_message = "Database access must be either read or read_write."

  }


  # =======================================================
  # EXISTING / SHARED ACCESS VALIDATION
  # =======================================================
  #
  # Existing and shared databases need:
  #
  #   database_name
  #   access
  #
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      contains(
        [
          "existing",
          "shared"
        ],
        service.persistence.mode
      )
      ?
      (
        service.persistence.database_name != null
        &&
        service.persistence.access != null
      )
      :
      true

    ])

    error_message = "Persistence modes 'existing' and 'shared' require database_name and access."

  }


  # =======================================================
  # NEW / TEMPORARY DATABASE VALIDATION
  # =======================================================
  #
  # The platform needs engine and size to provision these.
  #
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      contains(
        [
          "new",
          "temporary"
        ],
        service.persistence.mode
      )
      ?
      (
        service.persistence.engine != null
        &&
        service.persistence.size != null
      )
      :
      true

    ])

    error_message = "Persistence modes 'new' and 'temporary' require engine and size."

  }


  # =======================================================
  # ENGINE VALIDATION
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      service.persistence.engine == null
      ?
      true
      :
      contains(
        [
          "postgres",
          "mysql",
          "aurora-postgres",
          "aurora-mysql",
          "mongodb"
        ],
        service.persistence.engine
      )

    ])

    error_message = "Database engine must be one of: postgres, mysql, aurora-postgres, aurora-mysql, mongodb."

  }


  # =======================================================
  # DATABASE SIZE VALIDATION
  # =======================================================

  validation {

    condition = alltrue([

      for service_name, service in var.services :

      service.persistence.size == null
      ?
      true
      :
      contains(
        [
          "small",
          "medium",
          "large",
          "xlarge"
        ],
        service.persistence.size
      )

    ])

    error_message = "Database size must be one of: small, medium, large, xlarge."

  }

}