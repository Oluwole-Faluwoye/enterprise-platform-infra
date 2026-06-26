variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
}

variable "subnet_ids" {
  description = "Private subnets used by EKS nodes"
}

variable "jenkins_role_arn" {
  description = "Jenkins role allowed to administer EKS"
  type        = string
  default     = null
}

# =========================================================
# ALLOWED KUBERNETES API CIDRS
# =========================================================

variable "allowed_k8s_api_cidrs" {
  description = "CIDRs allowed to access the EKS API endpoint"
  type        = list(string)
}

variable "terraform_role_arn" {
  description = "Terraform deployment role"
  type        = string
  default     = null
}