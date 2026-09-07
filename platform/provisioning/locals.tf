# =========================================================
# PLATFORM PROVISIONING LOCALS
# =========================================================

locals {

  # =======================================================
  # ENVIRONMENT INFRASTRUCTURE
  # =======================================================

  vpc_id = var.environment_context.vpc_id

  private_subnet_ids = var.environment_context.private_subnet_ids

  database_subnet_ids = var.environment_context.database_subnet_ids


  # =======================================================
  # RESOLVED PLATFORM CONTRACT
  # =======================================================

  resolved_services = module.resolver.resolved_services


  # =======================================================
  # APPLICATIONS REQUIRING SECURITY GROUPS
  # =======================================================

  application_services = {
    for service_name, service in local.resolved_services :
    service_name => service
  }


  # =======================================================
  # DATABASE CREATION REQUESTS
  # =======================================================

  database_creation_requests = (
    module.resolver.database_creation_requests
  )


  # =======================================================
  # EXISTING DATABASE ACCESS
  # =======================================================

  existing_database_requests = (
    module.resolver.existing_database_requests
  )


  # =======================================================
  # SHARED DATABASE ACCESS
  # =======================================================

  shared_database_requests = (
    module.resolver.shared_database_requests
  )

  # =========================================================
  # DATABASE ACCESS REQUESTS
  # =========================================================
  #
  # Existing and shared requests are handled by the Database
  # Access Golden Path.
  #
  # These requests do NOT create databases.
  # =========================================================

  database_access_requests = (
    module.resolver.database_access_requests
  )


  # =========================================================
  # DATABASE REGISTRY
  # =========================================================
  #
  # The platform registry is the authoritative source for
  # databases that applications are allowed to reference.
  #
  # Databases created by the current provisioning run produce
  # catalog entries from the Database Golden Path.
  #
  # Those newly-created entries are merged with the existing
  # platform registry.
  #
  # Developer contracts never contain physical AWS identifiers.
  # =========================================================

  # =========================================================
  # DATABASES CREATED THIS RUN
  # =========================================================

  database_created_this_run = {

    for service_name, database in module.database :

    database.catalog_entry.logical_name => database.catalog_entry

  }


  # =========================================================
  # AUTHORITATIVE DATABASE CATALOG
  # =========================================================

  database_catalog = module.database_registry.database_catalog


  # =========================================================
  # ACCEESS RESOLUTION AGAINST THE DATABASE CATALOG 
  # i.e this would check the existing database catalog to see if the 
  # database that was requested access to is in the catalog
  # =========================================================

  database_access_resolution = module.database_access.access_decisions
}

