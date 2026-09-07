region = "us-east-1"

# =========================================================
# ENVIRONMENT LIFECYCLE
# =========================================================

enable_eks = true

enable_nat_gateway = true

# =========================================================
# NETWORKING
# =========================================================

vpc_cidr = "10.10.0.0/16"

azs = [
  "us-east-1a",
  "us-east-1b"
]

public_subnets = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_subnets = [
  "10.10.11.0/24",
  "10.10.12.0/24"
]

database_subnets = [
  "10.10.21.0/24",
  "10.10.22.0/24"
]

cluster_name = "enterprise-platform-dev"

# =========================================================
# PLATFORM
# =========================================================

project_name = "enterprise-platform"

environment = "dev"

admin_user_arn = "arn:aws:iam::761018849945:user/Admin-User"

domain_name = "dreammyles.online"

external_dns_namespace = "kube-system"

external_dns_service_account = "external-dns"