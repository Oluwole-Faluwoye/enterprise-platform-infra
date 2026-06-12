variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
}

variable "subnet_ids" {
  description = "Private subnets used by EKS nodes"
}

variable "enable_jenkins" {
  description = "Create Jenkins EKS access entry"
  type        = bool
  default     = false
}