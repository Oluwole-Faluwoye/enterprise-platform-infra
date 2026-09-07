# =========================================================
# DATABASE REGISTRY STORE
# =========================================================

terraform {

  required_version = ">= 1.6.0"

  required_providers {

    aws = {

      source  = "hashicorp/aws"
      version = "~> 6.0"

    }

  }

}


# =========================================================
# DYNAMODB TABLE
# =========================================================

resource "aws_dynamodb_table" "this" {

  name = var.table_name

  billing_mode = var.billing_mode

  hash_key = "environment"

  range_key = "logical_name"

  attribute {

    name = "environment"

    type = "S"

  }

  attribute {

    name = "logical_name"

    type = "S"

  }

  point_in_time_recovery {

    enabled = true

  }

  server_side_encryption {

    enabled = true

  }

  tags = local.common_tags

}