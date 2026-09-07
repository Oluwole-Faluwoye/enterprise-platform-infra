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
# PLATFORM PROVISIONING TEST
# =========================================================
#
# This test validates:
#
# Developer service contracts
#          ↓
#      Resolver
#          ↓
# Resolved platform decisions
#          ↓
#      Provisioner
#          ↓
# Environment infrastructure context
#
# The test intentionally does NOT depend on Bootstrap
# remote state.
#
# In the real platform workflow, environment_context will
# come from the selected environment (dev/staging/prod).
# =========================================================

module "provisioning" {
  source = "./.."

  project     = "enterprise-platform"
  environment = "dev"
  aws_region  = "us-east-1"

  database_secret_registry = {
    customer = {
      secret_arn      = "arn:aws:secretsmanager:us-east-1:761018849945:secret:enterprise-platform/dev/customer"
      secret_name     = "enterprise-platform/dev/customer"
      management_mode = "external"
    }
  }

  database_registry = {

    customer = {

      logical_name = "customer"

      environment = "dev"

      engine = "postgres"

      resource_type = "rds"

      resource_id = "enterprise-platform-dev-customer"

      port = 5432

      endpoint = "customer-dev.example.internal"

      reader_endpoint = null

      security_group_id = "sg-customer"

      subnet_group_name = "enterprise-platform-dev-customer"

      status = "active"

      management_mode = "external"

    }

  }

  # -------------------------------------------------------
  # ENVIRONMENT INFRASTRUCTURE CONTEXT
  # -------------------------------------------------------
  #
  # These values represent the infrastructure context
  # supplied by the DEV environment.
  #
  # They are infrastructure inputs to the provisioner,
  # NOT developer-facing service contract values.
  #
  # Do not put AWS resource IDs into the service contracts.
  #
  environment_context = {
    vpc_id = "vpc-test"

    private_subnet_ids = [
      "subnet-private-test-1",
      "subnet-private-test-2"
    ]

    database_subnet_ids = [
      "subnet-database-test-1",
      "subnet-database-test-2"
    ]

    cluster_name = "enterprise-platform-dev"
  }

  # -------------------------------------------------------
  # TEST SERVICE CONTRACTS
  # -------------------------------------------------------
  #
  # These represent what developers request from the
  # platform.
  #
  # Notice that there are no:
  #
  #   vpc_id
  #   subnet_id
  #   security_group_id
  #   AWS-specific identifiers
  #
  # The resolver interprets intent and the provisioner
  # supplies infrastructure context.
  # -------------------------------------------------------

  services = {

    payment-service = {

      runtime = "java"

      team = "payments"

      persistence = {
        enabled = true
        mode    = "new"

        engine        = "postgres"
        size          = "medium"
        database_name = "payment"
      }
    }

    order-service = {

      runtime = "nodejs"

      team = "orders"

      persistence = {
        enabled = false
        mode    = "none"
      }
    }

    fraud-service = {

      runtime = "python"

      team = "risk"

      persistence = {
        enabled = true
        mode    = "temporary"

        engine        = "mongodb"
        size          = "large"
        database_name = "fraud_experiment"
      }
    }

    reporting-service = {

      runtime = "java"

      team = "analytics"

      persistence = {
        enabled = true
        mode    = "existing"

        database_name = "customer"
        access        = "read"
      }
    }

    customer-api = {

      runtime = "nodejs"

      team = "customer"

      persistence = {
        enabled = true
        mode    = "shared"

        database_name = "customer"
        access        = "read_write"
      }
    }
  }
}