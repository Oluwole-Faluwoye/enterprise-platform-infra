# =========================================================
# STANDARD RDS
#
# Supported engines:
#   postgres
#   mysql
# =========================================================

resource "aws_db_instance" "this" {

  count = local.is_rds ? 1 : 0

  identifier = local.database_identifier

  engine = var.engine

  instance_class = local.instance_class

  db_name = var.database_name

  username = "platform_admin"

  manage_master_user_password = true

  port = (
    var.engine == "postgres"
    ? 5432
    : 3306
  )

  allocated_storage = (
    var.size == "small"
    ? 20
    : var.size == "medium"
    ? 50
    : var.size == "large"
    ? 100
    : 200
  )

  max_allocated_storage = (
    var.size == "small"
    ? 50
    : var.size == "medium"
    ? 100
    : var.size == "large"
    ? 500
    : 1000
  )

  storage_type = "gp3"

  storage_encrypted = true

  db_subnet_group_name = aws_db_subnet_group.this[0].name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  deletion_protection = local.deletion_protection

  multi_az = local.multi_az

  backup_retention_period = local.effective_backup_retention

  backup_window = "03:00-04:00"

  maintenance_window = "sun:04:00-sun:05:00"

  auto_minor_version_upgrade = true

  skip_final_snapshot = false

  final_snapshot_identifier = "${local.database_identifier}-final"

  copy_tags_to_snapshot = true

  apply_immediately = false

  publicly_accessible = false

  tags = merge(
    local.common_tags,
    {
      Name   = local.database_identifier
      Engine = var.engine
      Size   = var.size
    }
  )

}