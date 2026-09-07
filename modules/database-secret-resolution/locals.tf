locals {
  secret_resolutions = {
    for service_name, decision in var.access_decisions :
    service_name => {
      service_name      = decision.service_name
      database_name     = decision.database_name
      access            = decision.access
      team      = decision.team
      namespace = decision.namespace
      mode              = decision.mode
      approval_required = decision.approval_required

      database = decision.database

      secret = (
        contains(
          keys(var.database_secret_registry),
          decision.database_name
        )
        ? var.database_secret_registry[decision.database_name]
        : null
      )

      secret_exists = contains(
        keys(var.database_secret_registry),
        decision.database_name
      )
    }
  }

  valid_secret_resolutions = {
    for service_name, resolution in local.secret_resolutions :
    service_name => resolution
    if resolution.secret_exists
  }

  missing_secret_resolutions = {
    for service_name, resolution in local.secret_resolutions :
    service_name => resolution
    if !resolution.secret_exists
  }

  approval_required = {
    for service_name, resolution in local.valid_secret_resolutions :
    service_name => resolution
    if resolution.approval_required
  }

  automatic_secret_access = {
    for service_name, resolution in local.valid_secret_resolutions :
    service_name => resolution
    if !resolution.approval_required
  }
}