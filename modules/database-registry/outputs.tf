# =========================================================
# DATABASE REGISTRY OUTPUTS
# =========================================================

output "database_catalog" {

  description = "Authoritative platform database catalog"

  value = local.database_catalog

}


output "platform_managed_catalog" {

  description = "Databases owned and created by the platform"

  value = local.platform_managed_catalog

}


output "externally_managed_catalog" {

  description = "Databases registered with the platform but externally managed"

  value = local.externally_managed_catalog

}


output "imported_catalog" {

  description = "Databases imported into the platform registry"

  value = local.imported_catalog

}