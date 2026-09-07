locals {

  # =========================================================
  # SERVICE NAMES
  # =========================================================

  service_names = keys(var.services)


  # =========================================================
  # APPLICATION SECURITY GROUP NAMES
  #
  # The platform generates these.
  #
  # Developers never provide AWS security-group IDs.
  # =========================================================

  application_security_group_names = {

    for service_name, service in var.services :

    service_name => lower(
      "${var.project}-${var.environment}-${service_name}"
    )

  }


  # =========================================================
  # DATABASE REQUESTS
  # =========================================================

  database_requests = {

    for service_name, service in var.services :

    service_name => {

      service_name = service_name

      mode = service.persistence.mode

      engine = try(
        service.persistence.engine,
        null
      )

      size = try(
        service.persistence.size,
        null
      )

      database_name = try(
        service.persistence.database_name,
        null
      )

      access = try(
        service.persistence.access,
        null
      )

    }

    if service.persistence.enabled

  }


  # =========================================================
  # DATABASE CREATION REQUESTS
  #
  # new
  # temporary
  # =========================================================

  database_creation_requests = {

    for service_name, request in local.database_requests :

    service_name => request

    if contains(
      [
        "new",
        "temporary"
      ],
      request.mode
    )

  }


  # =========================================================
  # NEW DATABASE REQUESTS
  # =========================================================

  new_database_requests = {

    for service_name, request in local.database_requests :

    service_name => request

    if request.mode == "new"

  }


  # =========================================================
  # TEMPORARY DATABASE REQUESTS
  # =========================================================

  temporary_database_requests = {

    for service_name, request in local.database_requests :

    service_name => request

    if request.mode == "temporary"

  }


  # =========================================================
  # EXISTING DATABASE REQUESTS
  # =========================================================

  existing_database_requests = {

    for service_name, request in local.database_requests :

    service_name => request

    if request.mode == "existing"

  }


  # =========================================================
  # SHARED DATABASE REQUESTS
  # =========================================================

  shared_database_requests = {

    for service_name, request in local.database_requests :

    service_name => request

    if request.mode == "shared"

  }


  # =========================================================
  # READ-ONLY EXISTING DATABASE ACCESS
  # =========================================================

  existing_read_requests = {

    for service_name, request in local.existing_database_requests :

    service_name => request

    if request.access == "read"

  }


  # =========================================================
  # EXISTING DATABASE READ/WRITE ACCESS
  #
  # This normally requires database-owner approval.
  # =========================================================

  existing_read_write_requests = {

    for service_name, request in local.existing_database_requests :

    service_name => request

    if request.access == "read_write"

  }


  # =========================================================
  # SHARED DATABASE READ ACCESS
  # =========================================================

  shared_read_requests = {

    for service_name, request in local.shared_database_requests :

    service_name => request

    if request.access == "read"

  }


  # =========================================================
  # SHARED DATABASE READ/WRITE ACCESS
  # =========================================================

  shared_read_write_requests = {

    for service_name, request in local.shared_database_requests :

    service_name => request

    if request.access == "read_write"

  }


  # =========================================================
  # DATABASE ACCESS REQUESTS
  # =========================================================
  #
  # Existing/shared persistence does not create a database.
  #
  # Instead, the resolver produces a normalized access request
  # that the provisioning layer can consume.
  #
  # The resolver determines:
  #
  #   - database logical name
  #   - access level
  #   - persistence mode
  #   - platform action
  #   - whether approval is required
  #
  # The resolver does NOT determine:
  #
  #   - database endpoint
  #   - database ID
  #   - database security-group ID
  #   - secret ARN
  #   - database credentials
  #
  # Those belong to the provisioning/access layer.
  # =========================================================

  access_requests = {

    for service_name, request in local.database_requests :

    service_name => {

      service_name = service_name

      team = var.services[service_name].team

      namespace = lower(
        var.services[service_name].team
      )

      database_name = request.database_name

      mode = request.mode

      action = "access"

      access = request.access

      approval_required = (
        (
          request.mode == "existing"
          &&
          request.access == "read_write"
        )
        ||
        (
          request.mode == "shared"
          &&
          request.access == "read_write"
        )
      )

    }

    if contains(
      [
        "existing",
        "shared"
      ],
      request.mode
    )

  }

  # =========================================================
  # RESOLVED SERVICES
  # =========================================================

  resolved_services = {

    for service_name, service in var.services :

    service_name => {

      name = service_name

      runtime = service.runtime

      team = service.team

      namespace = lower(service.team)

      environment = var.environment


      # -----------------------------------------------------
      # Application identity
      # -----------------------------------------------------

      application_security_group_name = (
        local.application_security_group_names[service_name]
      )


      # -----------------------------------------------------
      # Persistence
      # -----------------------------------------------------

      persistence = {

        enabled = service.persistence.enabled

        mode = service.persistence.mode

        action = (
          service.persistence.mode == "new"
          || service.persistence.mode == "temporary"
          ? "create"
          : service.persistence.mode == "existing"
          || service.persistence.mode == "shared"
          ? "access"
          : "none"
        )

        engine = try(
          service.persistence.engine,
          null
        )

        size = try(
          service.persistence.size,
          null
        )

        database_name = try(
          service.persistence.database_name,
          null
        )

        access = try(
          service.persistence.access,
          null
        )

        approval_required = (
          contains(
            [
              "existing",
              "shared"
            ],
            service.persistence.mode
          ) &&
          service.persistence.access == "read_write"
        )

      }

    }

  }


  # =========================================================
  # STATELESS SERVICES
  # =========================================================

  stateless_services = {

    for service_name, service in var.services :

    service_name => service

    if !service.persistence.enabled

  }


  # =========================================================
  # PLATFORM COUNTS
  # =========================================================

  application_count = length(
    local.service_names
  )

  database_request_count = length(
    local.database_requests
  )

  database_creation_count = length(
    local.database_creation_requests
  )

  new_database_count = length(
    local.new_database_requests
  )

  temporary_database_count = length(
    local.temporary_database_requests
  )

  existing_database_count = length(
    local.existing_database_requests
  )

  shared_database_count = length(
    local.shared_database_requests
  )

  existing_read_count = length(
    local.existing_read_requests
  )

  existing_read_write_count = length(
    local.existing_read_write_requests
  )

  shared_read_count = length(
    local.shared_read_requests
  )

  shared_read_write_count = length(
    local.shared_read_write_requests
  )

  access_request_count = length(
    local.access_requests
  )

  approval_required_count = length([
    for service_name, request in local.access_requests :
    service_name
    if request.approval_required
  ])

}