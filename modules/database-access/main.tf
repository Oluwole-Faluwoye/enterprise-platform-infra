# =========================================================
# DATABASE ACCESS GOLDEN PATH
# =========================================================
#
# This module translates a normalized database access request
# into a platform access decision.
#
# It does NOT:
#
# - create databases
# - create credentials
# - create secrets
# - create IAM roles
# - create Kubernetes resources
#
# Those responsibilities belong to later Golden Paths.
# =========================================================

check "database_access_requests_reference_known_databases" {
  assert {
    condition = length(local.invalid_access_decisions) == 0

    error_message = join(
      "\n",
      [
        for service_name, decision in local.invalid_access_decisions :
        "Service '${service_name}' requested database '${decision.database_name}', but that database is not registered in the platform database catalog."
      ]
    )
  }
}