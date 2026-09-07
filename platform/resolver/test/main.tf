terraform {

  required_providers {

    aws = {

      source  = "hashicorp/aws"
      version = "~> 6.0"

    }

  }

}


provider "aws" {

  region = "us-east-1"

}


# =========================================================
# PLATFORM RESOLVER TEST
#
# This test validates the resolver only.
#
# It does NOT provide:
#
#   VPC IDs
#   subnet IDs
#   security-group IDs
#   RDS IDs
#   IAM ARNs
#
# Those belong to the platform infrastructure layer.
# =========================================================

module "resolver" {

  source = "./.."

  project     = "enterprise-platform"
  environment = "dev"


  # =======================================================
  # SERVICE CONTRACTS
  # =======================================================

  services = {

    # -----------------------------------------------------
    # NEW DATABASE
    # -----------------------------------------------------

    payment-service = {

      runtime = "java"

      team = "payments"

      persistence = {

        enabled = true

        mode = "new"

        engine = "postgres"

        size = "medium"

        database_name = "payment"

      }

    }


    # -----------------------------------------------------
    # STATELESS SERVICE
    # -----------------------------------------------------

    order-service = {

      runtime = "nodejs"

      team = "orders"

      persistence = {

        enabled = false

        mode = "none"

      }

    }


    # -----------------------------------------------------
    # TEMPORARY DATABASE
    # -----------------------------------------------------

    fraud-service = {

      runtime = "python"

      team = "risk"

      persistence = {

        enabled = true

        mode = "temporary"

        engine = "mongodb"

        size = "large"

        database_name = "fraud_experiment"

      }

    }


    # -----------------------------------------------------
    # EXISTING DATABASE - READ
    # -----------------------------------------------------

    reporting-service = {

      runtime = "java"

      team = "analytics"

      persistence = {

        enabled = true

        mode = "existing"

        database_name = "customer"

        access = "read"

      }

    }


    # -----------------------------------------------------
    # SHARED DATABASE - READ/WRITE
    # -----------------------------------------------------

    customer-api = {

      runtime = "nodejs"

      team = "customer"

      persistence = {

        enabled = true

        mode = "shared"

        database_name = "customer"

        access = "read_write"

      }

    }

  }

}