terraform {

  backend "s3" {

    bucket = "enterprise-platform-tf-state-761018849945"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks"

    encrypt = true
  }
}