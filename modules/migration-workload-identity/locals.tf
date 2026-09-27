locals {
  enabled_migrations = {
    for service_name, migration in var.migration_requests :
    service_name => migration
    if migration.enabled
    && contains(keys(var.database_secret_arns), service_name)
  }

  migration_identities = {
    for service_name, migration in local.enabled_migrations :
    service_name => {
      service_name         = service_name
      namespace            = lookup(var.service_namespaces, service_name, "default")
      service_account_name = "${service_name}-migration"
      iam_role_name        = "${var.project}-${var.environment}-${service_name}-migration"
      database_secret_arn  = var.database_secret_arns[service_name]
      migration_engine     = migration.engine
    }
  }
}
