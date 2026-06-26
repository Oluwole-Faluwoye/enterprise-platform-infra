# 08 - EKS Access, Role Assumption and Platform Security

## Overview

This document explains how Kubernetes access is managed within the platform.

The objective was to implement an enterprise-style access model where administrative access is granted through IAM roles rather than directly through IAM users.

This approach provides:

* Centralized authorization
* Improved auditing
* Reduced privilege sprawl
* Separation of duties
* Enterprise governance

The final design allows:

* Jenkins to administer the cluster
* Terraform to administer the cluster
* Platform Engineers to assume approved roles
* Future RBAC expansion

---

# Initial Architecture

During the initial implementation, EKS was configured using:

```hcl
enable_cluster_creator_admin_permissions = true
```

Purpose:

Automatically grant cluster-admin permissions to the identity that created the cluster.

Advantages:

* Simple setup
* Easy learning experience

Disadvantages:

* Not enterprise-friendly
* Hidden access dependency
* Difficult to audit
* Ties cluster access to creator identity

---

# Why This Was Changed

Enterprise environments rarely grant permanent cluster-admin permissions directly to users.

Instead:

Platform Engineer

↓

Assume Role

↓

EKS Access Entry

↓

Kubernetes API

This creates a controlled authorization path.

---

# EKS Access Entries

Modern Amazon EKS uses:

```text
Access Entries
```

instead of relying solely on:

```text
aws-auth ConfigMap
```

Access Entries provide:

* Centralized IAM integration
* Better auditing
* Terraform management
* Fine-grained authorization

---

# Original Problem

After EKS deployment:

Command:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name devops-cluster
```

appeared successful.

However:

```bash
kubectl get nodes
```

returned:

```text
the server has asked for the client to provide credentials
```

---

# Investigation

Verified EKS cluster existed.

Command:

```bash
aws eks list-clusters \
--region us-east-1
```

Output:

```json
{
  "clusters": [
    "devops-cluster"
  ]
}
```

Cluster was healthy.

---

# Verify Current AWS Identity

Command:

```bash
aws sts get-caller-identity
```

Output:

```json
{
  "Arn":
  "arn:aws:iam::761018849945:user/Admin-User"
}
```

Observation:

Local workstation authenticated as:

```text
Admin-User
```

---

# Verify Access Entries

Command:

```bash
aws eks list-access-entries \
--cluster-name devops-cluster \
--region us-east-1
```

Output:

```text
AWSServiceRoleForAmazonEKS

devops-nodes role

jenkins-ec2-role

terraform-deployer-role
```

Observation:

Admin-User was missing.

---

# Root Cause

The cluster was configured to allow:

```text
terraform-deployer-role
```

but not:

```text
Admin-User
```

Therefore:

AWS Authentication

Succeeded

↓

Kubernetes Authorization

Failed

---

# Enterprise Design Decision

Rather than granting:

```text
Admin-User
```

direct cluster-admin permissions,

the platform adopted:

```text
Admin-User

↓

Assume terraform-deployer-role

↓

EKS Access Entry

↓

Cluster Admin
```

Benefits:

* Better auditing
* Least privilege
* Centralized access management

---

# Terraform IAM Role Configuration

Role:

```text
terraform-deployer-role
```

Purpose:

Infrastructure provisioning

EKS administration

Cluster bootstrap

GitOps bootstrap

---

# Original Trust Relationship

Initial configuration:

```hcl
Principal = {
  AWS = var.jenkins_role_arn
}
```

Only Jenkins could assume the role.

---

# Problem

Local workstation could not assume:

```text
terraform-deployer-role
```

because:

```text
Admin-User
```

was not trusted.

---

# Updated Trust Policy

Terraform modified to allow:

```hcl
Principal = {
  AWS = [
    var.admin_user_arn,
    var.jenkins_role_arn
  ]
}
```

Result:

Both:

* Admin-User
* Jenkins

can assume:

```text
terraform-deployer-role
```

---

# Managing Trust Policies Through Terraform

Decision:

Manage IAM trust relationships through Terraform.

Reason:

* Version controlled
* Auditable
* Repeatable
* Consistent

Manual IAM changes were avoided.

---

# EKS Access Entry Configuration

The EKS module was updated.

Original:

```hcl
enable_cluster_creator_admin_permissions = true
```

Final:

```hcl
enable_cluster_creator_admin_permissions = false
```

---

# Explicit Access Entries

Configured:

```hcl
access_entries = {

  terraform_admin = {

    principal_arn =
      "arn:aws:iam::761018849945:role/terraform-deployer-role"

    policy_associations = {

      admin = {

        policy_arn =
          "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

        access_scope = {
          type = "cluster"
        }

      }

    }

  }

}
```

---

# Jenkins Access Entry

Configured:

```hcl
jenkins_admin = {

  principal_arn =
    "arn:aws:iam::761018849945:role/jenkins-ec2-role"

}
```

Purpose:

Allow Jenkins to:

* Bootstrap ArgoCD
* Create namespaces
* Deploy applications
* Manage cluster resources

---

# Applying Terraform Changes

After modifications:

```bash
terraform plan
```

Review:

```bash
terraform apply
```

Validation:

```bash
aws eks list-access-entries \
--cluster-name devops-cluster \
--region us-east-1
```

Expected:

```text
terraform-deployer-role

jenkins-ec2-role
```

appear as access entries.

---

# AWS CLI Role Assumption

Created AWS profile.

File:

```text
~/.aws/config
```

Configuration:

```ini
[profile terraform]

role_arn=arn:aws:iam::761018849945:role/terraform-deployer-role

source_profile=default

region=us-east-1
```

---

# Validation

Command:

```bash
aws sts get-caller-identity \
--profile terraform
```

Expected:

```text
assumed-role/terraform-deployer-role
```

---

# Updating Kubeconfig

Command:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name devops-cluster \
--role-arn arn:aws:iam::761018849945:role/terraform-deployer-role
```

Purpose:

Configure kubectl to authenticate using the deployment role.

---

# Cluster Validation

Verify nodes:

```bash
kubectl get nodes
```

Expected:

```text
Ready
```

---

# Verifying Access Entries

List entries:

```bash
aws eks list-access-entries \
--cluster-name devops-cluster \
--region us-east-1
```

Describe entry:

```bash
aws eks describe-access-entry \
--cluster-name devops-cluster \
--principal-arn arn:aws:iam::761018849945:role/terraform-deployer-role
```

---

# Platform Security Model

Final Access Architecture:

Platform Engineer

↓

Admin-User

↓

Assume terraform-deployer-role

↓

Amazon EKS Access Entry

↓

Cluster Admin

---

# Jenkins Access Model

Jenkins EC2

↓

jenkins-ec2-role

↓

terraform-deployer-role

↓

Amazon EKS

↓

ArgoCD Bootstrap

↓

GitOps Deployment

---

# Security Benefits

Benefits achieved:

* No permanent cluster-admin users
* Role-based authorization
* Auditable access
* Terraform-managed permissions
* Reduced privilege sprawl
* Enterprise governance

---

# Lessons Learned

Kubernetes authentication and authorization are separate processes.

Successful AWS authentication does not guarantee Kubernetes access.

EKS Access Entries provide a cleaner and more manageable authorization model than relying on creator permissions.

IAM trust relationships should be managed through Terraform rather than manually.

Role assumption provides a more secure and enterprise-aligned access pattern than granting cluster-admin permissions directly to users.

Explicit access entries improve security, governance, auditing, and operational consistency across environments.

---

# Final State

The platform now uses:

* Terraform-managed IAM
* Terraform-managed EKS Access Entries
* Explicit Cluster Administration Roles
* Jenkins Platform Automation
* GitOps Deployment
* Enterprise Role Assumption

This architecture mirrors modern enterprise Kubernetes access management practices and eliminates dependence on hidden creator permissions.
