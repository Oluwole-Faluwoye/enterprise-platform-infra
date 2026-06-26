variable "jenkins_role_arn" {
  type = string
}

variable "admin_user_arn" {

  description = "Admin IAM user allowed to assume terraform-deployer-role"

  type = string
}