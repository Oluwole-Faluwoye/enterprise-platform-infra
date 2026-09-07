

module "database" {
  source = "./.."

  project     = "enterprise-platform"
  environment = var.environment

  vpc_id = "vpc-00000000000000000"

  private_subnet_ids = [
    "subnet-00000000000000001",
    "subnet-00000000000000002"
  ]

  database_name = "payment"

  application_name = "payment-service"

  engine = "postgres"

  size = "medium"

  application_security_group_id = "sg-00000000000000000"

  backup_retention_period = null
}