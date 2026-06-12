# 06 - Migrate Terraform To Platform Repository

## Objective

Move Terraform infrastructure code from legacy training projects into the enterprise-platform-infra repository.

This establishes a dedicated Infrastructure as Code repository for the platform.

---

## Source Repository

Legacy Location:

```text
AWS-Cloud-Program/project-1-devops/terraform
```

Contained:

* VPC Module
* EKS Module
* Jenkins Module
* ECR Module

---

## Target Repository

```text
enterprise-platform-infra/
```

Repository Structure:

```text
enterprise-platform-infra/

├── docs/
│   ├── concepts/
│   ├── runbooks/
│   └── interview-notes/
│
├── terraform/
│   ├── envs/
│   │   └── dev/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── providers.tf
│   │       ├── terraform.tfvars
│   │       └── setup.sh
│   │
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── ecr/
│       └── jenkins/
│
└── README.md
```

---

## Migration Procedure

### Step 1

Create Terraform Structure

```bash
mkdir -p terraform/envs/dev
mkdir -p terraform/modules
```

---

### Step 2

Copy Existing Modules

```bash
cp -r ../project-1-devops/terraform/modules/* terraform/modules/
```

Modules:

* vpc
* eks
* ecr
* jenkins

---

### Step 3

Copy Environment Files

```bash
cp ../project-1-devops/terraform/envs/dev/* terraform/envs/dev/
```

Files:

* main.tf
* providers.tf
* variables.tf
* outputs.tf
* terraform.tfvars

---

### Step 4

Verify Structure

Command:

```bash
find terraform -maxdepth 3 -type f
```

Expected:

```text
terraform/envs/dev/main.tf
terraform/envs/dev/providers.tf
terraform/envs/dev/variables.tf
terraform/envs/dev/outputs.tf
terraform/envs/dev/terraform.tfvars

terraform/modules/vpc/main.tf
terraform/modules/eks/main.tf
terraform/modules/ecr/main.tf
terraform/modules/jenkins/main.tf
```

---

## Terraform Initialization

Navigate:

```bash
cd terraform/envs/dev
```

Initialize:

```bash
terraform init
```

Expected:

```text
Terraform has been successfully initialized
```

Downloads:

* AWS Provider
* Kubernetes Provider
* EKS Module
* VPC Module

---

## Validation

Command:

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

## Planning

Command:

```bash
terraform plan
```

Example Result:

```text
Plan: 71 to add, 0 to change, 0 to destroy
```

Resources:

* VPC
* Public Subnets
* Private Subnets
* NAT Gateway
* Internet Gateway
* EKS Cluster
* Managed Node Group
* IAM Roles
* KMS Keys
* ECR Repository

---

## Disk Space Issue Encountered

Error:

```text
Failed to install provider

There is not enough space on the disk
```

Root Cause:

Terraform provider caches from historical training projects consumed over 15 GB.

Discovery:

```text
Terrform-Notebook = 10.74 GB
Terraform = 5.12 GB
```

Many old `.terraform` directories contained duplicated provider downloads.

Resolution:

```powershell
Get-ChildItem "AWS-Cloud-Program" -Recurse -Directory -Force |
Where-Object { $_.Name -eq ".terraform" } |
Remove-Item -Recurse -Force
```

Recovered:

```text
16+ GB
```

---

## Verification

Commands:

```bash
terraform init
terraform validate
terraform plan
```

All commands completed successfully.

---

## Outcome

Terraform infrastructure code is now fully migrated into enterprise-platform-infra and is ready for deployment into AWS.
