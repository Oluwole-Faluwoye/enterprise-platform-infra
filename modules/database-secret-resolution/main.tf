check "database_secret_references_exist" {
  assert {
    condition = length(local.missing_secret_resolutions) == 0

    error_message = join(
      "\n",
      [
        for service_name, resolution in local.missing_secret_resolutions :
        "Service '${service_name}' requires credentials for database '${resolution.database_name}', but no secret is registered for that database."
      ]
    )
  }
}