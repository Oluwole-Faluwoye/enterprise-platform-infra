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

# =========================================================
#  IP ADDRESSES ALLOWED TO SSH INTO JENKINS INSTANCE
# =========================================================

variable "allowed_jenkins_ssh_cidrs" {
  description = "CIDRs allowed to access the EKS API endpoint"
  type        = list(string)
}
