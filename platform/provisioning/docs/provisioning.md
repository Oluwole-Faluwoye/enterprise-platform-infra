Provisioning

Responsibility

The Provisioner executes resolved platform actions using environment
context.

It does not expose Bootstrap implementation details to services.

Environment context

The Provisioner receives values such as:

vpc_id
private_subnet_ids
database_subnet_ids
cluster_name
vpc_cidr

Application Security Group

Provisioning creates an application SG for the service.

The module was extended with:

variable "vpc_cidr" {
  type = string
}

This supports DNS egress.

Database relationship

The Provisioner composes the application SG and database Golden Path.

It creates service-specific DB egress:

Application SG
    ↓ TCP database port
Database SG

Why cross-cutting rules live here

The application SG module should not own knowledge of every database.

The composition layer has both resources available and therefore owns
the relationship.

Validation

Use:

terraform fmt
terraform validate
terraform plan

Then commit and push so Jenkins performs the deployment.