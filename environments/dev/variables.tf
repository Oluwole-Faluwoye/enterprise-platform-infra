variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "enable_eks" {
  description = "Toggle EKS creation"
  type        = bool
  default     = false
}

# =========================================================
# ALLOWED KUBERNETES API CIDRS
# =========================================================

variable "allowed_k8s_api_cidrs" {
  description = "CIDRs allowed to access the EKS API endpoint"
  type        = list(string)
}