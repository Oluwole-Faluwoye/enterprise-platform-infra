# =========================================================
# DATABASE REGISTRY STORE LOCALS
# =========================================================

locals {

  common_tags = {

    Project     = var.project
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "database-registry"

  }

}