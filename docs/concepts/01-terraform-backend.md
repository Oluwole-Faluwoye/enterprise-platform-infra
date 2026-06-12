# Terraform Remote State Backend

## Overview

Before provisioning any infrastructure, Terraform requires a mechanism to track resources that it creates and manages.

Terraform stores this information in a file called the state file:

```text
terraform.tfstate
```

The state file acts as Terraform's source of truth and maps Terraform resources to actual AWS resources.

Without state management, Terraform would not know:

* What resources already exist
* What changes have been made
* What resources need to be updated
* What resources should be destroyed

---

# Why Local State Is Not Suitable For Production

By default, Terraform stores state locally.

Example:

```text
terraform.tfstate
```

Problems with local state:

* State can be lost if the machine fails
* State cannot be shared safely across teams
* Multiple engineers can accidentally overwrite infrastructure
* No state locking mechanism exists

For enterprise environments, local state is considered unsafe.

---

# Remote State Architecture

To solve these problems, AWS S3 and DynamoDB are used.

Architecture:

Developer
↓
Terraform
↓
S3 Bucket (State Storage)
↓
DynamoDB Table (State Locking)

---

# S3 Bucket Purpose

The S3 bucket stores the Terraform state file.

Benefits:

* Centralized storage
* Team collaboration
* Versioning support
* Durability
* Backup capability

Terraform continuously reads and updates the state file stored in S3.

---

# DynamoDB Table Purpose

DynamoDB is used for state locking.

When a Terraform operation starts:

```bash
terraform apply
```

Terraform acquires a lock.

Example:

Engineer A runs:

```bash
terraform apply
```

At the same time:

Engineer B runs:

```bash
terraform apply
```

Without locking:

* State corruption can occur
* Infrastructure conflicts can occur
* Resources can become inconsistent

With DynamoDB locking:

Engineer A acquires the lock.

Engineer B must wait until the lock is released.

This prevents concurrent modifications.

---

# Why PAY_PER_REQUEST Was Used

The DynamoDB billing mode selected is:

```hcl
billing_mode = "PAY_PER_REQUEST"
```

This means AWS automatically scales read and write capacity.

Benefits:

* No capacity planning required
* Cost effective for Terraform backends
* Automatically scales with demand
* Ideal for low-frequency operations

This is the recommended approach for Terraform backend locking.

---

# Commands Used

Initialize Terraform:

```bash
terraform init
```

Review execution plan:

```bash
terraform plan
```

Provision resources:

```bash
terraform apply
```

Destroy resources:

```bash
terraform destroy
```

Validate configuration:

```bash
terraform validate
```

Format Terraform files:

```bash
terraform fmt -recursive
```

Show current state:

```bash
terraform show
```

List managed resources:

```bash
terraform state list
```

---

# Key Production Concepts Learned

* Infrastructure as Code (IaC)
* Terraform State Management
* Remote State Backends
* State Locking
* Team Collaboration
* Infrastructure Consistency
* AWS S3
* AWS DynamoDB
* Enterprise Terraform Best Practices

---

# Interview Question

Q: Why do we use DynamoDB with Terraform?

A:

DynamoDB provides state locking. It prevents multiple engineers or automation pipelines from modifying the same Terraform state simultaneously, reducing the risk of state corruption and infrastructure conflicts.

---

# Real-World Usage

Almost every enterprise Terraform deployment uses:

* Remote state storage
* State locking
* Version-controlled infrastructure

because infrastructure must be treated like software and managed safely across teams.
