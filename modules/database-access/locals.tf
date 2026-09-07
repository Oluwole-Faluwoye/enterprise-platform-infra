locals {
  access_decisions = {
    for service_name, request in var.access_requests :

    service_name => {
      service_name  = request.service_name
      database_name = request.database_name
      team          = request.team
      namespace     = request.namespace
      mode          = request.mode
      action        = request.action
      access        = request.access

      approval_required = request.approval_required

      database_exists = contains(
        keys(var.database_catalog),
        request.database_name
      )

      database = (
        contains(
          keys(var.database_catalog),
          request.database_name
        )
        ? var.database_catalog[request.database_name]
        : null
      )
    }
  }

  valid_access_decisions = {
    for service_name, decision in local.access_decisions :
    service_name => decision
    if decision.database_exists
  }

  invalid_access_decisions = {
    for service_name, decision in local.access_decisions :
    service_name => decision
    if !decision.database_exists
  }

  approval_required = {
    for service_name, decision in local.valid_access_decisions :
    service_name => decision
    if decision.approval_required
  }

  automatic_access = {
    for service_name, decision in local.valid_access_decisions :
    service_name => decision
    if !decision.approval_required
  }
}