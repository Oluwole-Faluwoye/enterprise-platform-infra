locals {

  # =========================================================
  # ENGINE CLASSIFICATION
  # =========================================================

  is_rds = contains(
    [
      "postgres",
      "mysql"
    ],
    var.engine
  )

  is_aurora = contains(
    [
      "aurora-postgres",
      "aurora-mysql"
    ],
    var.engine
  )

  is_documentdb = var.engine == "mongodb"


  # =========================================================
  # RDS SIZE MAPPING
  #
  # Developer chooses:
  #
  #   small
  #   medium
  #   large
  #   xlarge
  #
  # Platform chooses the AWS implementation.
  # =========================================================

  rds_instance_classes = {

    postgres = {

      small  = "db.t4g.small"
      medium = "db.t4g.medium"
      large  = "db.r6g.large"
      xlarge = "db.r6g.xlarge"

    }

    mysql = {

      small  = "db.t4g.small"
      medium = "db.t4g.medium"
      large  = "db.r6g.large"
      xlarge = "db.r6g.xlarge"

    }

  }


  # =========================================================
  # AURORA SIZE MAPPING
  # =========================================================

  aurora_instance_classes = {

    aurora-postgres = {

      small  = "db.t4g.medium"
      medium = "db.r6g.large"
      large  = "db.r6g.xlarge"
      xlarge = "db.r6g.2xlarge"

    }

    aurora-mysql = {

      small  = "db.t4g.medium"
      medium = "db.r6g.large"
      large  = "db.r6g.xlarge"
      xlarge = "db.r6g.2xlarge"

    }

  }


  # =========================================================
  # DOCUMENTDB SIZE MAPPING
  #
  # Developer-facing engine:
  #
  #   mongodb
  #
  # AWS implementation:
  #
  #   Amazon DocumentDB
  # =========================================================

  documentdb_instance_classes = {

    small  = "db.t4g.medium"
    medium = "db.r6g.large"
    large  = "db.r6g.xlarge"
    xlarge = "db.r6g.2xlarge"

  }


  # =========================================================
  # RESOLVED INSTANCE CLASS
  #
  # This is the abstraction boundary.
  # =========================================================

  instance_class = (
    local.is_rds
    ? local.rds_instance_classes[var.engine][var.size]
    : local.is_aurora
    ? local.aurora_instance_classes[var.engine][var.size]
    : local.is_documentdb
    ? local.documentdb_instance_classes[var.size]
    : null
  )

  # =========================================================
  # DATABASE PORT
  # =========================================================

  database_port = (
    var.engine == "postgres"
    || var.engine == "aurora-postgres"
    ? 5432
    : var.engine == "mongodb"
    ? 27017
    : 3306
  )


  # =========================================================
  # ENVIRONMENT POLICY
  #
  # Developers select the environment.
  # The platform determines operational defaults.
  # =========================================================

  environment_defaults = {

    dev = {

      deletion_protection = false
      multi_az            = false
      backup_retention    = 7

    }

    staging = {

      deletion_protection = true
      multi_az            = true
      backup_retention    = 7

    }

    prod = {

      deletion_protection = true
      multi_az            = true
      backup_retention    = 30

    }

  }


  # =========================================================
  # EFFECTIVE PLATFORM SETTINGS
  # =========================================================

  deletion_protection = (
    local.environment_defaults[var.environment].deletion_protection
  )

  multi_az = (
    local.environment_defaults[var.environment].multi_az
  )

  effective_backup_retention = (
    var.backup_retention_period != null
    ? var.backup_retention_period
    : local.environment_defaults[var.environment].backup_retention
  )


  # =========================================================
  # DATABASE IDENTIFIERS
  # =========================================================

  database_identifier = lower(
  replace(
    "${var.project}-${var.environment}-${var.database_name}",
    "_",
    "-"
  )
)

  subnet_group_name = lower(
    replace(
      "${var.project}-${var.environment}-${var.database_name}",
      "_",
      "-"
    )
  )

  security_group_name = lower(
    replace(
      "${var.project}-${var.environment}-${var.database_name}-db",
      "_",
      "-"
    )
  )


  # =========================================================
  # COMMON TAGS
  # =========================================================

  common_tags = {

    Project     = var.project
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "database-golden-path"

  }

}