# Infrastructure Pipeline

## Purpose

This pipeline provisions and manages AWS infrastructure using Terraform.

The pipeline does not use long-lived AWS credentials.

Instead, Jenkins assumes a dedicated deployment role using AWS STS.

---

## Repository

enterprise-platform-infra

---

## Jenkinsfile Location

enterprise-platform-infra/Jenkinsfile

---

## Security Model

Jenkins EC2
↓
jenkins-ec2-role
↓
sts:AssumeRole
↓
terraform-deployer-role
↓
Terraform Operations

This follows the principle of least privilege.

The Jenkins EC2 role contains only:

- ECR access
- CloudWatch access
- SSM access
- STS AssumeRole

Infrastructure permissions are delegated to the deployment role.

---

## Pipeline Flow

GitHub
↓
Jenkins
↓
Assume Deployment Role
↓
Terraform Init
↓
Terraform Plan
↓
Terraform Apply

---

## Resources Managed

Examples:

- VPC
- Subnets
- Internet Gateway
- NAT Gateway
- ECR
- Jenkins EC2
- EKS
- IAM
- Route53
- Load Balancers
- ArgoCD Infrastructure

---

## Why This Exists

Separates infrastructure deployment from application deployment.

Provides:

- Auditability
- Security
- Reproducibility
- Infrastructure as Code