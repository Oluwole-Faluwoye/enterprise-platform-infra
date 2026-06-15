variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "user_data_path" {
  type = string
}

variable "home_ip" {
  description = "Home public IP in CIDR format"
  type        = string
}

