output "secret_resolutions" {
  description = "Resolved database credential secret mappings"
  value       = local.secret_resolutions
}

output "valid_secret_resolutions" {
  description = "Database access requests with registered secrets"
  value       = local.valid_secret_resolutions
}

output "missing_secret_resolutions" {
  description = "Database access requests without registered secrets"
  value       = local.missing_secret_resolutions
}

output "approval_required" {
  description = "Secret resolutions requiring database access approval"
  value       = local.approval_required
}

output "automatic_secret_access" {
  description = "Secret resolutions that do not require approval"
  value       = local.automatic_secret_access
}
