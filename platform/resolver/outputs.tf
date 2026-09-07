# =========================================================
# PLATFORM RESOLVER OUTPUTS
# =========================================================
#
# This file contains ALL outputs from the resolver.
#
# The resolver outputs platform decisions.
#
# It does NOT output AWS resource IDs because the resolver
# does not create or own AWS infrastructure.
# =========================================================


# =========================================================
# RESOLVED SERVICES
# =========================================================

output "resolved_services" {

  description = "Normalized service contracts resolved by the platform"

  value = local.resolved_services

}


# =========================================================
# DATABASE REQUESTS
# =========================================================

output "database_requests" {

  description = "All database-related requests identified by the resolver"

  value = local.database_requests

}


# =========================================================
# DATABASE CREATION REQUESTS
# =========================================================
#
# Includes:
#
#   new
#   temporary
#
# These are candidates for infrastructure provisioning.
# =========================================================

output "database_creation_requests" {

  description = "Database requests that require database infrastructure"

  value = local.database_creation_requests

}


# =========================================================
# NEW DATABASE REQUESTS
# =========================================================

output "new_database_requests" {

  description = "Requests for new persistent databases"

  value = local.new_database_requests

}


# =========================================================
# TEMPORARY DATABASE REQUESTS
# =========================================================

output "temporary_database_requests" {

  description = "Requests for temporary databases"

  value = local.temporary_database_requests

}


# =========================================================
# EXISTING DATABASE REQUESTS
# =========================================================
#
# These represent workloads consuming an existing database.
#
# They do NOT automatically create another database.
# =========================================================

output "existing_database_requests" {

  description = "Requests to consume existing databases"

  value = local.existing_database_requests

}


# =========================================================
# SHARED DATABASE REQUESTS
# =========================================================
#
# These represent workloads intentionally sharing an existing
# database.
#
# Shared write access requires stronger governance.
# =========================================================

output "shared_database_requests" {

  description = "Requests to use shared databases"

  value = local.shared_database_requests

}


# =========================================================
# DATABASE ACCESS REQUESTS
# =========================================================
#
# Consolidated view of existing/shared database access.
# =========================================================

output "database_access_requests" {

   description = "Normalized database access requests for existing and shared databases"

  value = local.access_requests

}

# =========================================================
# ACCESS REQUEST COUNT
# =========================================================

output "access_request_count" {

  description = "Number of existing/shared database access requests"

  value = local.access_request_count

}


# =========================================================
# APPROVAL REQUIRED COUNT
# =========================================================

output "approval_required_count" {

  description = "Number of database access requests requiring approval"

  value = local.approval_required_count

}

# =========================================================
# APPROVAL REQUIREMENTS
# =========================================================
#
# The resolver identifies whether an access request requires
# database-owner approval.
#
# The resolver does NOT perform the approval itself.
#
# The future approval workflow will consume this output.
# =========================================================

output "approval_required" {

  description = "Approval requirements for database access requests"

  value = {

    for service_name, request in local.access_requests :

    service_name => request.approval_required

  }

}


# =========================================================
# APPLICATION COUNT
# =========================================================

output "application_count" {

  description = "Number of services submitted to the resolver"

  value = local.application_count

}


# =========================================================
# DATABASE REQUEST COUNT
# =========================================================

output "database_request_count" {

  description = "Number of database-related requests"

  value = local.database_request_count

}


# =========================================================
# DATABASE CREATION COUNT
# =========================================================

output "database_creation_count" {

  description = "Number of database creation requests"

  value = local.database_creation_count

}


# =========================================================
# EXISTING DATABASE COUNT
# =========================================================

output "existing_database_count" {

  description = "Number of existing database requests"

  value = local.existing_database_count

}


# =========================================================
# SHARED DATABASE COUNT
# =========================================================

output "shared_database_count" {

  description = "Number of shared database requests"

  value = local.shared_database_count

}

# =========================================================
# PLATFORM ACTIONS
# =========================================================
#
# Normalized actions consumed by the provisioning layer.
#
# Developers specify persistence mode.
# The resolver converts that intent into an operational
# platform action.
# =========================================================

output "platform_actions" {

  description = "Normalized platform actions for submitted services"

  value = {
    for service_name, service in local.resolved_services :

    service_name => {
      application_security_group = service.application_security_group_name

      persistence = {
        action        = service.persistence.action
        mode          = service.persistence.mode
        engine        = service.persistence.engine
        size          = service.persistence.size
        database_name = service.persistence.database_name
        access        = service.persistence.access
      }
    }
  }

}
