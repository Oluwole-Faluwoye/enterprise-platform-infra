# =========================================================
# AURORA CLUSTER
#
# Supported:
#   aurora-postgres
#   aurora-mysql
# =========================================================

resource "aws_rds_cluster" "this" {

  count = local.is_aurora ? 1 : 0

  cluster_identifier = local.database_identifier

  engine = (
    var.engine == "aurora-postgres"
    ? "aurora-postgresql"
    : "aurora-mysql"
  )

  database_name = var.database_name

  master_username = "platform_admin"

  manage_master_user_password = true

  db_subnet_group_name = aws_db_subnet_group.this[0].name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  storage_encrypted = true

  backup_retention_period = local.effective_backup_retention

  preferred_backup_window = "03:00-04:00"

  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection = local.deletion_protection

  copy_tags_to_snapshot = true

  skip_final_snapshot = false

  final_snapshot_identifier = "${local.database_identifier}-final"

  tags = merge(
    local.common_tags,
    {
      Name   = local.database_identifier
      Engine = var.engine
      Size   = var.size
    }
  )

}


# =========================================================
# AURORA INSTANCE
# =========================================================

resource "aws_rds_cluster_instance" "this" {

  count = local.is_aurora ? (
    local.multi_az ? 2 : 1
  ) : 0

  identifier = "${local.database_identifier}-${count.index + 1}"

  cluster_identifier = aws_rds_cluster.this[0].id

  instance_class = local.instance_class

  engine = aws_rds_cluster.this[0].engine

  publicly_accessible = false

  auto_minor_version_upgrade = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.database_identifier}-${count.index + 1}"
    }
  )

}