# Jenkins AssumeRole Architecture

## Overview

This project follows the Principle of Least Privilege by separating the permissions used to run Jenkins from the permissions used to provision AWS infrastructure.

Instead of granting broad infrastructure permissions directly to the Jenkins EC2 instance, Jenkins assumes a dedicated deployment role whenever infrastructure changes are required.

## Architecture

```text
Jenkins EC2
    │
    ▼
jenkins-ec2-role
    │
    ├── ECR
    ├── CloudWatch
    ├── SSM
    └── STS:AssumeRole
            │
            ▼
terraform-deployer-role
            │
            ├── EKS
            ├── IAM
            ├── EC2
            ├── VPC
            ├── Route53
            ├── Load Balancers
            ├── Auto Scaling
            └── Terraform Managed Resources
```

## Why Not Give Jenkins Full Permissions?

A common anti-pattern is attaching broad infrastructure permissions directly to the Jenkins EC2 role.

Example:

```text
Jenkins EC2
    │
    ▼
AdministratorAccess
```

This creates a large attack surface because any compromise of Jenkins immediately grants administrative access to the AWS account.

Instead, this project isolates infrastructure permissions into a separate deployment role.

## Jenkins EC2 Role Responsibilities

The Jenkins EC2 role only contains permissions required to operate Jenkins:

* Push and pull container images from Amazon ECR
* Write logs to CloudWatch
* Access the instance using AWS Systems Manager Session Manager
* Assume the deployment role

The Jenkins role does not contain permissions to create or manage infrastructure resources.

## Terraform Deployer Role Responsibilities

The Terraform deployment role contains the permissions required to provision and manage infrastructure using Terraform.

Examples include:

* Amazon EKS
* IAM Roles and Policies
* VPC Resources
* EC2 Resources
* Elastic Load Balancers
* Route53
* Auto Scaling
* CloudWatch Resources

Terraform runs using this role rather than the Jenkins EC2 role.

## AssumeRole Flow

Before running Terraform, Jenkins requests temporary credentials from AWS Security Token Service (STS).

Example:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/terraform-deployer-role \
  --role-session-name jenkins
```

AWS returns temporary credentials which are used by Terraform for the duration of the deployment.

## Benefits

* Principle of Least Privilege
* Reduced blast radius if Jenkins is compromised
* Clear separation between CI/CD operations and infrastructure administration
* Easier auditing and permission management
* Aligns with enterprise DevOps and Platform Engineering practices

## Deployment Stages

This repository uses feature toggles to progressively deploy infrastructure.

Stage A:

* VPC
* ECR

Stage B:

* Jenkins

Stage C:

* EKS
* NAT Gateway

Stage D:

* GitOps
* ArgoCD
* Platform Services

The IAM architecture remains consistent across all stages.


# Jenkins AssumeRole Architecture

## Overview

This project follows the Principle of Least Privilege by separating the permissions used to run Jenkins from the permissions used to provision AWS infrastructure.

Instead of granting broad infrastructure permissions directly to the Jenkins EC2 instance, Jenkins assumes a dedicated deployment role whenever infrastructure changes are required.

## Architecture

```text
Jenkins EC2
    │
    ▼
jenkins-ec2-role
    │
    ├── ECR
    ├── CloudWatch
    ├── SSM
    └── STS:AssumeRole
            │
            ▼
terraform-deployer-role
            │
            ├── EKS
            ├── IAM
            ├── EC2
            ├── VPC
            ├── Route53
            ├── Load Balancers
            ├── Auto Scaling
            └── Terraform Managed Resources
```

## Why Not Give Jenkins Full Permissions?

A common anti-pattern is attaching broad infrastructure permissions directly to the Jenkins EC2 role.

Example:

```text
Jenkins EC2
    │
    ▼
AdministratorAccess
```

This creates a large attack surface because any compromise of Jenkins immediately grants administrative access to the AWS account.

Instead, this project isolates infrastructure permissions into a separate deployment role.

## Jenkins EC2 Role Responsibilities

The Jenkins EC2 role only contains permissions required to operate Jenkins:

* Push and pull container images from Amazon ECR
* Write logs to CloudWatch
* Access the instance using AWS Systems Manager Session Manager
* Assume the deployment role

The Jenkins role does not contain permissions to create or manage infrastructure resources.

## Terraform Deployer Role Responsibilities

The Terraform deployment role contains the permissions required to provision and manage infrastructure using Terraform.

Examples include:

* Amazon EKS
* IAM Roles and Policies
* VPC Resources
* EC2 Resources
* Elastic Load Balancers
* Route53
* Auto Scaling
* CloudWatch Resources

Terraform runs using this role rather than the Jenkins EC2 role.

## AssumeRole Flow

Before running Terraform, Jenkins requests temporary credentials from AWS Security Token Service (STS).

Example:

```bash
aws sts assume-role \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/terraform-deployer-role \
  --role-session-name jenkins
```

AWS returns temporary credentials which are used by Terraform for the duration of the deployment.

## Benefits

* Principle of Least Privilege
* Reduced blast radius if Jenkins is compromised
* Clear separation between CI/CD operations and infrastructure administration
* Easier auditing and permission management
* Aligns with enterprise DevOps and Platform Engineering practices

## Deployment Stages

This repository uses feature toggles to progressively deploy infrastructure.

Stage A:

* VPC
* ECR

Stage B:

* Jenkins

Stage C:

* EKS
* NAT Gateway

Stage D:

* GitOps
* ArgoCD
* Platform Services

The IAM architecture remains consistent across all stages.
