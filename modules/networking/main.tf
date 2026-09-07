module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs = var.azs

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway

  # DEV cost-control model:
  # one NAT Gateway when enabled.
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  map_public_ip_on_launch = true

  public_subnet_tags = var.enable_kubernetes_tags ? {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}

  private_subnet_tags = var.enable_kubernetes_tags ? {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  } : {}

  tags = merge(
    {
      Terraform = "true"
    },
    var.environment != null ? {
      Environment = var.environment
    } : {}
  )
}
resource "aws_subnet" "database" {
  count = length(var.database_subnets)

  vpc_id = module.vpc.vpc_id

  cidr_block = var.database_subnets[count.index]

  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.name}-database-${var.azs[count.index]}"
    Tier = "database"
  }
}

# =========================================================
# DATABASE SUBNET ROUTING
# =========================================================

resource "aws_route_table" "database" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.name}-database-rt"
    Tier = "database"
  }
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnets)

  subnet_id = aws_subnet.database[count.index].id

  route_table_id = aws_route_table.database.id
}