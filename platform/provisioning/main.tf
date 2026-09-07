# =========================================================
# PLATFORM PROVISIONING
# =========================================================
#
# Connects:
#
# Developer contract
#        ↓
# Resolver
#        ↓
# Environment context + resolved decisions
#        ↓
# Golden Paths / Terraform modules
#
# The provisioner may know infrastructure IDs.
# The resolver and developer contract must not.
# =========================================================



# =========================================================
# PLATFORM RESOLVER
# =========================================================
#
# The resolver interprets developer intent.
#
# It does not create AWS resources.
# =========================================================


module "resolver" {

  source = "../resolver"

  project = var.project

  environment = var.environment

  services = var.services

}


# =========================================================
# APPLICATION SECURITY GROUPS
# =========================================================
#
# # The provisioning layer creates AWS security groups
# using the VPC supplied by the selected environment context.
#
# Developers never provide:
#
#   vpc_id
#   security_group_id

# =========================================================

module "application_security_group" {

  for_each = local.application_services

  source = "../../modules/application-security-group"

  project = var.project

  environment = var.environment

  application_name = each.key

  vpc_id = var.environment_context.vpc_id

}

# =========================================================
# DATABASE GOLDEN PATH
# =========================================================
#
# The resolver determines whether a service needs database
# creation.
#
# Only requests classified as:
#
#   action = create
#
# reach this Golden Path.
#
# Existing/shared database requests are handled separately
# by the database access workflow.
# =========================================================

module "database" {

  for_each = local.database_creation_requests

  source = "../../modules/database"

  project     = var.project
  environment = var.environment

  # Environment-provided infrastructure
  vpc_id = var.environment_context.vpc_id

  private_subnet_ids = var.environment_context.database_subnet_ids

  # Resolver-provided platform decisions
  database_name = each.value.database_name
  engine        = each.value.engine
  size          = each.value.size

  # Platform-resolved application dependency
  application_name = each.key

  application_security_group_id = (
    module.application_security_group[each.key].security_group_id
  )
}

# =========================================================
# DATABASE REGISTRY GOLDEN PATH
# =========================================================
#
# The registry is the authoritative source for databases
# available to platform access workflows.
#
# It combines:
#
#   1. Previously registered databases
#   2. Databases created during this provisioning run
#
# The registry does not create database infrastructure.
# =========================================================

module "database_registry" {

  source = "../../modules/database-registry"

  registered_databases = var.database_registry

  created_databases = local.database_created_this_run

}

# =========================================================
# DATABASE ACCESS GOLDEN PATH
# =========================================================
#
# Existing/shared database requests are resolved against
# the authoritative database registry.
#
# This module does not create databases.
# =========================================================

module "database_access" {
  source = "../../modules/database-access"

  project     = var.project
  environment = var.environment

  access_requests  = local.database_access_requests
  database_catalog = local.database_catalog
}

# =========================================================
# DATABASE SECRET RESOLUTION
# =========================================================

module "database_secret_resolution" {
  source = "../../modules/database-secret-resolution"

  project     = var.project
  environment = var.environment

  access_decisions         = module.database_access.access_decisions
  database_secret_registry = var.database_secret_registry
}

# =========================================================
# DATABASE WORKLOAD IDENTITY
# =========================================================

module "database_workload_identity" {
  source = "../../modules/database-workload-identity"

  count = var.environment_context.enable_eks ? 1 : 0

  project     = var.project
  environment = var.environment

  oidc_provider_arn = var.environment_context.oidc_provider_arn
  oidc_provider     = var.environment_context.oidc_provider

  secret_resolutions = module.database_secret_resolution.secret_resolutions

  approved_services = var.approved_services
}

