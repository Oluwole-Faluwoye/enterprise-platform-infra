# =========================================================
# DATABASE IDENTIFIERS
# =========================================================

output "database_identifier" {

  description = "Logical database identifier"

  value = local.database_identifier

}


output "engine" {

  description = "Database Golden Path engine"

  value = var.engine

}


output "size" {

  description = "Database Golden Path size"

  value = var.size

}


output "resolved_instance_class" {

  description = "AWS instance class selected by the platform"

  value = local.instance_class

}


# =========================================================
# DATABASE CONNECTION
# =========================================================

output "database_port" {

  description = "Database port selected by the platform"

  value = local.database_port

}


# =========================================================
# RDS
# =========================================================

output "rds_endpoint" {

  description = "RDS endpoint"

  value = local.is_rds ? aws_db_instance.this[0].address : null

}


output "rds_port" {

  description = "RDS port"

  value = local.is_rds ? aws_db_instance.this[0].port : null

}


# =========================================================
# AURORA
# =========================================================

output "aurora_endpoint" {

  description = "Aurora writer endpoint"

  value = local.is_aurora ? aws_rds_cluster.this[0].endpoint : null

}


output "aurora_reader_endpoint" {

  description = "Aurora reader endpoint"

  value = local.is_aurora ? aws_rds_cluster.this[0].reader_endpoint : null

}


# =========================================================
# DOCUMENTDB
# =========================================================

output "documentdb_endpoint" {

  description = "DocumentDB cluster endpoint"

  value = local.is_documentdb ? aws_docdb_cluster.this[0].endpoint : null

}


output "documentdb_reader_endpoint" {

  description = "DocumentDB reader endpoint"

  value = local.is_documentdb ? aws_docdb_cluster.this[0].reader_endpoint : null

}


# =========================================================
# SECURITY
# =========================================================

output "security_group_id" {

  description = "Database security group ID"

  value = aws_security_group.database.id

}


# =========================================================
# SUBNET GROUP
# =========================================================

output "subnet_group_name" {

  description = "Database subnet group name"

  value = (
    local.is_documentdb
    ? aws_docdb_subnet_group.this[0].name
    : aws_db_subnet_group.this[0].name
  )

}


# =========================================================
# PLATFORM POLICY
# =========================================================

output "deletion_protection" {

  description = "Effective deletion protection policy"

  value = local.deletion_protection

}


output "multi_az" {

  description = "Effective Multi-AZ policy"

  value = local.multi_az

}


output "backup_retention_period" {

  description = "Effective backup retention period"

  value = local.effective_backup_retention

}

# =========================================================
# DATABASE CATALOG
# =========================================================

output "catalog_entry" {

  description = "Normalized database metadata consumed by the platform database catalog"

  value = {

    logical_name = var.database_name

    environment = var.environment

    engine = var.engine

    resource_type = (
      local.is_rds
      ? "rds"
      : local.is_aurora
      ? "aurora"
      : local.is_documentdb
      ? "documentdb"
      : null
    )

    resource_id = local.database_identifier

    port = local.database_port

    endpoint = (
      local.is_rds
      ? aws_db_instance.this[0].address
      : local.is_aurora
      ? aws_rds_cluster.this[0].endpoint
      : local.is_documentdb
      ? aws_docdb_cluster.this[0].endpoint
      : null
    )

    reader_endpoint = (
      local.is_aurora
      ? aws_rds_cluster.this[0].reader_endpoint
      : local.is_documentdb
      ? aws_docdb_cluster.this[0].reader_endpoint
      : null
    )

    security_group_id = aws_security_group.database.id

    subnet_group_name = (
      local.is_documentdb
      ? aws_docdb_subnet_group.this[0].name
      : aws_db_subnet_group.this[0].name
    )

    status = "active"
  }

}