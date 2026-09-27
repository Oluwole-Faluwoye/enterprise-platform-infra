output "migration_identities" {
  description = "Resolved migration workload identities"
  value       = local.migration_identities
}

output "iam_role_arns" {
  description = "IAM role ARNs created for migration workloads"

  value = {
    for service_name, role in aws_iam_role.migration :
    service_name => role.arn
  }
}

output "iam_role_names" {
  description = "IAM role names created for migration workloads"

  value = {
    for service_name, role in aws_iam_role.migration :
    service_name => role.name
  }
}

output "service_accounts" {
  description = "Migration Kubernetes ServiceAccounts"

  value = {
    for service_name, identity in local.migration_identities :
    service_name => identity.service_account_name
  }
}

output "namespaces" {
  description = "Migration namespaces"

  value = {
    for service_name, identity in local.migration_identities :
    service_name => identity.namespace
  }
}
