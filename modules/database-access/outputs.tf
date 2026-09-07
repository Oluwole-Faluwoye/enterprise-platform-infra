output "access_decisions" {
  description = "Resolved database access decisions"

  value = local.access_decisions
}

output "valid_access_decisions" {
  description = "Database access requests resolved against registered databases"

  value = local.valid_access_decisions
}

output "invalid_access_decisions" {
  description = "Database access requests referencing unknown databases"

  value = local.invalid_access_decisions
}

output "approval_required" {
  description = "Database access requests requiring approval"

  value = local.approval_required
}

output "automatic_access" {
  description = "Database access requests that do not require approval"

  value = local.automatic_access
}