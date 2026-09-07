# =========================================================
# RDS / AURORA SUBNET GROUP
# =========================================================

resource "aws_db_subnet_group" "this" {

  count = (
    local.is_rds || local.is_aurora
    ? 1
    : 0
  )

  name = local.subnet_group_name

  subnet_ids = var.private_subnet_ids

  description = "Database subnet group for ${local.database_identifier}"

  tags = merge(
    local.common_tags,
    {
      Name = local.subnet_group_name
    }
  )

}


# =========================================================
# DOCUMENTDB SUBNET GROUP
# =========================================================

resource "aws_docdb_subnet_group" "this" {

  count = local.is_documentdb ? 1 : 0

  name = local.subnet_group_name

  subnet_ids = var.private_subnet_ids

  description = "DocumentDB subnet group for ${local.database_identifier}"

  tags = merge(
    local.common_tags,
    {
      Name = local.subnet_group_name
    }
  )

}