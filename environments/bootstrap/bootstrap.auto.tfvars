region = "us-east-1"

key_name = "us-east-1-key"

enable_ecr         = true
enable_jenkins     = true
enable_nat_gateway = false

vpc_name = "devops-vpc"
vpc_cidr = "10.0.0.0/16"

azs = [
  "us-east-1a",
  "us-east-1b"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]


# Replace admin_user_arn below with your AWS account admin user ARN
# admin_user_arn = "arn:aws:iam::<ACCOUNT_ID>:user/Admin-User"


admin_user_arn = "arn:aws:iam::761018849945:user/Admin-User"