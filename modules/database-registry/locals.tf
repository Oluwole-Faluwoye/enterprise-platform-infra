# =========================================================
# DATABASE REGISTRY LOCALS
# =========================================================

locals {

  # =======================================================
  # CURRENT PROVISIONING RUN
  # =======================================================

  platform_managed_databases = {

    for logical_name, database in var.created_databases :

    logical_name => merge(
      database,
      {
        management_mode = "platform"
      }
    )

  }


  # =======================================================
  # AUTHORITATIVE DATABASE CATALOG
  # =======================================================
  #
  # Existing registered databases are combined with
  # databases created during the current provisioning run.
  #
  # Current-run platform-managed databases take precedence.
  # =======================================================

  database_catalog = merge(

    var.registered_databases,

    local.platform_managed_databases

  )


  # =======================================================
  # PLATFORM-MANAGED DATABASES
  # =======================================================

  platform_managed_catalog = {

    for logical_name, database in local.database_catalog :

    logical_name => database

    if database.management_mode == "platform"

  }


  # =======================================================
  # EXTERNALLY-MANAGED DATABASES
  # =======================================================

  externally_managed_catalog = {

    for logical_name, database in local.database_catalog :

    logical_name => database

    if database.management_mode == "external"

  }


  # =======================================================
  # IMPORTED DATABASES
  # =======================================================

  imported_catalog = {

    for logical_name, database in local.database_catalog :

    logical_name => database

    if database.management_mode == "imported"

  }

}