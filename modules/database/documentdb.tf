# =========================================================
# AMAZON DOCUMENTDB
#
# Developer-facing engine:
#
#   mongodb
#
# AWS implementation:
#
#   Amazon DocumentDB
# =========================================================

resource "aws_docdb_cluster" "this" {

  count = local.is_documentdb ? 1 : 0

  cluster_identifier = local.database_identifier

  master_username = "platform_admin"

  manage_master_user_password = true

  db_subnet_group_name = aws_docdb_subnet_group.this[0].name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  storage_encrypted = true

  backup_retention_period = local.effective_backup_retention

  preferred_backup_window = "03:00-04:00"

  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = local.deletion_protection

  skip_final_snapshot = false

  final_snapshot_identifier = "${local.database_identifier}-final"

  tags = merge(
    local.common_tags,
    {
      Name   = local.database_identifier
      Engine = "mongodb"
      Size   = var.size
    }
  )

}


# =========================================================
# DOCUMENTDB INSTANCE
# =========================================================

resource "aws_docdb_cluster_instance" "this" {

  count = local.is_documentdb ? (
    local.multi_az ? 2 : 1
  ) : 0

  identifier = "${local.database_identifier}-${count.index + 1}"

  cluster_identifier = aws_docdb_cluster.this[0].id

  instance_class = local.instance_class

  engine = "docdb"

  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.database_identifier}-${count.index + 1}"
    }
  )

}