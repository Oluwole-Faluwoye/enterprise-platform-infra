# Enterprise Infrastructure Pipeline

## Purpose

The infrastructure pipeline manages AWS resources using Terraform.

The pipeline provisions and updates infrastructure in a controlled and auditable manner.

---

## Managed Resources

Examples:

* VPC
* ECR
* Jenkins EC2
* Security Groups
* EKS
* IAM Roles
* NAT Gateway
* VPC Endpoints

---

## Pipeline Flow

Checkout
↓
Assume Terraform Role
↓
Terraform Format Check
↓
Terraform Init
↓
Terraform Validate
↓
tfsec Scan
↓
Checkov Scan
↓
Terraform Plan
↓
Manual Approval
↓
Terraform Apply

---

## Stage Explanations

### Checkout

Retrieves the Terraform code from GitHub.

---

### Assume Terraform Role

Uses AWS STS to obtain temporary credentials.

Flow:

Jenkins EC2 Role
↓
AssumeRole
↓
Terraform Deployer Role

Purpose:

* Least privilege
* Temporary credentials
* Improved security

---

### Terraform Format Check

Validates Terraform formatting standards.

Purpose:

Maintain consistency.

---

### Terraform Init

Initializes Terraform providers and backend configuration.

Purpose:

Prepare Terraform execution environment.

---

### Terraform Validate

Validates Terraform syntax and configuration.

Purpose:

Catch configuration issues early.

---

### tfsec Scan

Performs Infrastructure as Code security scanning.

Checks:

* Security misconfigurations
* AWS best practices

Purpose:

Prevent insecure infrastructure deployments.

---

### Checkov Scan

Performs policy and compliance scanning.

Checks:

* CIS benchmarks
* Security policies
* Cloud best practices

Purpose:

Enforce governance controls.

---

### Terraform Plan

Creates an execution plan.

Purpose:

Show proposed infrastructure changes before deployment.

---

### Manual Approval

Requires human approval before applying changes.

Purpose:

Prevent accidental infrastructure modifications.

---

### Terraform Apply

Deploys approved infrastructure changes.

Purpose:

Provision or update AWS resources.

---

## Security Model

Jenkins EC2 Role
↓
STS AssumeRole
↓
Terraform Deployment Role
↓
AWS Resources

Benefits:

* No long-lived credentials
* Reduced blast radius
* Centralized permission management
* CloudTrail auditability

---

## Enterprise Controls

* Terraform Remote State
* DynamoDB State Locking
* KMS Encryption
* tfsec
* Checkov
* Manual Approval Gates
* Least Privilege IAM

These controls ensure infrastructure changes remain secure, traceable, and compliant.
