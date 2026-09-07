# =========================================================
# DATABASE SECURITY GROUP
# =========================================================

resource "aws_security_group" "database" {

  name        = local.security_group_name
  description = "Database access for ${local.database_identifier}"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = local.security_group_name
    }
  )
}


# =========================================================
# APPLICATION → DATABASE
#
# application_security_group_ids is an internal platform
# dependency. Developers do not provide security-group IDs.
# =========================================================

resource "aws_vpc_security_group_ingress_rule" "application" {

  security_group_id = aws_security_group.database.id

  referenced_security_group_id = var.application_security_group_id

  ip_protocol = "tcp"

  from_port = (
    local.is_documentdb
    ? 27017
    : local.is_aurora
    ? (
      var.engine == "aurora-postgres"
      ? 5432
      : 3306
    )
    : (
      var.engine == "postgres"
      ? 5432
      : 3306
    )
  )

  to_port = (
    local.is_documentdb
    ? 27017
    : local.is_aurora
    ? (
      var.engine == "aurora-postgres"
      ? 5432
      : 3306
    )
    : (
      var.engine == "postgres"
      ? 5432
      : 3306
    )
  )

  description = "Allow ${var.application_name} to access database"
}


# =========================================================
# EGRESS
# =========================================================

resource "aws_vpc_security_group_egress_rule" "all" {

  security_group_id = aws_security_group.database.id

  cidr_ipv4 = "0.0.0.0/0"

  ip_protocol = "-1"

  description = "Allow database outbound traffic"
}
