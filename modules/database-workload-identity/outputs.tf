output "workload_identities" {
  description = "Resolved workload identity mappings"
  value       = local.workload_identities
}

output "approval_required_workloads" {
  description = "Workloads waiting for explicit approval"
  value       = local.approval_required_workloads
}

output "automatic_workloads" {
  description = "Workloads eligible without approval"
  value       = local.automatic_workloads
}

output "iam_role_arns" {
  description = "IAM role ARNs created for eligible workloads"
  value = {
    for service_name, role in aws_iam_role.workload :
    service_name => role.arn
  }
}

output "iam_role_names" {
  description = "IAM role names created for eligible workloads"
  value = {
    for service_name, role in aws_iam_role.workload :
    service_name => role.name
  }
}

output "workload_namespaces" {
  description = "Kubernetes namespaces assigned to database workloads"

  value = {
    for service_name, identity in local.workload_identities :
    service_name => identity.namespace
  }
}