locals {
  valid_workloads = {
    for service_name, resolution in var.secret_resolutions :
    service_name => resolution
    if resolution.secret_exists
  }

  eligible_workloads = {
    for service_name, resolution in local.valid_workloads :
    service_name => resolution
    if !resolution.approval_required || contains(var.approved_services, service_name)
  }

  approval_required_workloads = {
    for service_name, resolution in local.valid_workloads :
    service_name => resolution
    if resolution.approval_required && !contains(var.approved_services, service_name)
  }

  automatic_workloads = {
    for service_name, resolution in local.valid_workloads :
    service_name => resolution
    if !resolution.approval_required
  }

  workload_identities = {
    for service_name, resolution in local.eligible_workloads :
    service_name => {
      service_name         = service_name
      team                 = resolution.team
      namespace            = resolution.namespace
      database_name        = resolution.database_name
      access               = resolution.access
      approval_required    = resolution.approval_required
      approved             = contains(var.approved_services, service_name)

      secret_arn            = resolution.secret.secret_arn
      secret_name           = resolution.secret.secret_name

      service_account_name  = service_name

      iam_role_name = "${var.project}-${var.environment}-${service_name}-database"
    }
  }
}