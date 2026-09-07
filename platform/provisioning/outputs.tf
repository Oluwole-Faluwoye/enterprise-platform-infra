# =========================================================
# PLATFORM PROVISIONING OUTPUTS
# =========================================================


# =========================================================
# PLATFORM NETWORK
# =========================================================

output "vpc_id" {

  description = "VPC used by platform workloads"

  value = local.vpc_id

}


output "private_subnet_ids" {

  description = "Private subnets used by platform workloads"

  value = local.private_subnet_ids

}


# =========================================================
# RESOLVED SERVICES
# =========================================================

output "resolved_services" {

  description = "Services resolved by the platform"

  value = local.resolved_services

}


# =========================================================
# APPLICATION SECURITY GROUPS
# =========================================================

output "application_security_groups" {

  description = "Application security groups created by the platform"

  value = {

    for service_name, security_group in module.application_security_group :

    service_name => {

      name = security_group.security_group_name

      id = security_group.security_group_id

    }

  }

}


# =========================================================
# DATABASE REQUESTS
# =========================================================

output "database_creation_requests" {

  description = "Database requests requiring infrastructure provisioning"

  value = local.database_creation_requests

}


# =========================================================
# EXISTING DATABASE ACCESS
# =========================================================

output "existing_database_requests" {

  description = "Existing database access requests"

  value = local.existing_database_requests

}


# =========================================================
# SHARED DATABASE ACCESS
# =========================================================

output "shared_database_requests" {

  description = "Shared database access requests"

  value = local.shared_database_requests

}

# =========================================================
# DATABASE ACCESS REQUESTS
# =========================================================

output "database_access_requests" {

  description = "Database access requests resolved for provisioning"

  value = local.database_access_requests

}


# =========================================================
# DATABASE REGISTRY
# =========================================================

output "database_catalog" {

  description = "Authoritative platform database registry available to application access resolution"

  value = local.database_catalog

}


output "database_created_this_run" {

  description = "Database catalog entries produced by the Database Golden Path during this provisioning run"

  value = local.database_created_this_run

}


output "platform_managed_databases" {

  description = "Databases owned and created by the platform"

  value = module.database_registry.platform_managed_catalog

}


output "externally_managed_databases" {

  description = "Databases registered with the platform but externally managed"

  value = module.database_registry.externally_managed_catalog

}


output "imported_databases" {

  description = "Databases imported into the platform registry"

  value = module.database_registry.imported_catalog

}

# =========================================================
# DATABASE ACCESS RESOLUTION
# =========================================================

output "database_access_approval_required" {
  description = "Database access requests requiring approval"

  value = module.database_access.approval_required
}

output "database_access_automatic" {
  description = "Database access requests that do not require approval"

  value = module.database_access.automatic_access
}

output "database_access_invalid" {
  description = "Database access requests referencing unknown databases"

  value = module.database_access.invalid_access_decisions
}

# =========================================================
# DATABASE SECRET RESOLUTION
# =========================================================

output "database_secret_resolutions" {
  description = "Resolved database credential secret mappings"

  value = module.database_secret_resolution.secret_resolutions
}

output "database_secret_valid" {
  description = "Database access requests with registered secrets"

  value = module.database_secret_resolution.valid_secret_resolutions
}

output "database_secret_missing" {
  description = "Database access requests without registered secrets"

  value = module.database_secret_resolution.missing_secret_resolutions
}

output "database_secret_approval_required" {
  description = "Secret resolutions requiring approval"

  value = module.database_secret_resolution.approval_required
}

output "database_secret_automatic" {
  description = "Secret resolutions that do not require approval"

  value = module.database_secret_resolution.automatic_secret_access
}

output "database_workload_identities" {
  description = "Database workload identity mappings"

  value = (
    length(module.database_workload_identity) > 0
    ? module.database_workload_identity[0].workload_identities
    : {}
  )
}

output "database_workload_approval_required" {
  description = "Database workloads waiting for explicit approval"

  value = (
    length(module.database_workload_identity) > 0
    ? module.database_workload_identity[0].approval_required_workloads
    : {}
  )
}

output "database_workload_automatic" {
  description = "Database workloads automatically approved"
  value = length(module.database_workload_identity) > 0 ? (
    module.database_workload_identity[0].automatic_workloads
  ) : {}
}

output "database_workload_iam_role_arns" {
  description = "IAM role ARNs created for eligible database workloads"

  value = (
    length(module.database_workload_identity) > 0
    ? module.database_workload_identity[0].iam_role_arns
    : {}
  )
}

output "database_workload_namespaces" {
  description = "Kubernetes namespaces assigned to database workloads"

  value = (
    length(module.database_workload_identity) > 0
    ? module.database_workload_identity[0].workload_namespaces
    : {}
  )
}

