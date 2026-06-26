# Amazon EBS CSI Driver Implementation Using IRSA in Amazon EKS

## Project Overview

As part of building an enterprise-grade cloud platform on AWS, I deployed an Amazon EKS cluster using Terraform to host containerized workloads and future GitOps-managed applications.

To support stateful applications requiring persistent storage, I implemented the Amazon EBS CSI (Container Storage Interface) Driver using IAM Roles for Service Accounts (IRSA).

This document explains why the EBS CSI Driver is required, the issue encountered during deployment, the troubleshooting process, the solution implemented, and the final outcome.

---

# What is the Amazon EBS CSI Driver?

The Amazon EBS CSI Driver is a Kubernetes storage driver that allows workloads running inside Amazon EKS to dynamically provision, attach, mount, and manage Amazon EBS volumes.

The driver acts as the bridge between Kubernetes and Amazon Elastic Block Store (EBS).

When an application requests persistent storage through a Persistent Volume Claim (PVC), the EBS CSI Driver communicates with AWS APIs to create and attach the required EBS volume automatically.

Without the driver, Kubernetes cannot dynamically provision Amazon EBS storage.

---

# Important Clarification

The Amazon EBS CSI Driver is **not required to create or operate an EKS cluster**.

An EKS cluster can function normally without the EBS CSI Driver.

The following components were already working before the EBS CSI Driver issue was resolved:

* EKS Control Plane
* Managed Node Group
* Worker Nodes
* CoreDNS
* kube-proxy
* VPC CNI
* Kubernetes API Server
* Cluster Networking

Evidence of this included:

```bash
kubectl get nodes
```

Output:

```text
NAME                         STATUS   ROLES    AGE
ip-10-0-3-146.ec2.internal   Ready    <none>
```

This confirmed that the cluster itself was healthy.

The actual issue was that the EBS CSI Add-on failed to start due to missing IAM Roles for Service Accounts (IRSA) configuration.

Therefore:

```text
EKS Cluster Deployment
✓ Successful

Worker Node Deployment
✓ Successful

Cluster Networking
✓ Successful

EBS CSI Driver Deployment
✗ Failed Initially
```

The cluster was operational, but it was not yet capable of dynamically provisioning persistent Amazon EBS storage.

---

# Why We Needed the EBS CSI Driver

Although the cluster was operational, future applications planned for the platform require persistent storage.

Examples include:

| Application                    | Storage Requirement                  |
| ------------------------------ | ------------------------------------ |
| Jenkins                        | Job history, plugins, workspace data |
| SonarQube                      | Analysis data and configuration      |
| PostgreSQL                     | Database files                       |
| MySQL                          | Database files                       |
| Prometheus                     | Metrics retention                    |
| Grafana                        | Dashboards and settings              |
| ArgoCD                         | Application state                    |
| Elasticsearch                  | Index storage                        |
| Loki                           | Log retention                        |
| RabbitMQ                       | Message persistence                  |
| Custom Enterprise Applications | Business data                        |

Without the EBS CSI Driver:

```text
Application
      ↓
Persistent Volume Claim (PVC)
      ↓
Pending
      ↓
No EBS Volume Created
      ↓
Application Cannot Start
```

With the EBS CSI Driver:

```text
Application
      ↓
Persistent Volume Claim (PVC)
      ↓
StorageClass
      ↓
EBS CSI Driver
      ↓
Amazon EBS Volume Created
      ↓
Volume Attached to Worker Node
      ↓
Application Starts Successfully
```

---

# Initial Environment

The Enterprise Platform environment consisted of:

## Networking

* AWS VPC
* Public Subnets
* Private Subnets
* NAT Gateway
* Route Tables

## CI/CD Platform

* Jenkins
* SonarQube
* Dedicated Persistent EBS Volume

## Infrastructure Services

* Amazon ECR
* IAM Roles and Policies
* Terraform Backend

  * Amazon S3 State Storage
  * DynamoDB State Locking

## Kubernetes Platform

* Amazon EKS
* Managed Node Group
* OIDC Provider
* EKS Access Entries

Infrastructure was provisioned using Terraform.

---

# Problem Encountered

Terraform successfully deployed the EKS cluster and node group.

However, the AWS-managed EBS CSI Add-on failed during deployment.

Add-on status:

```text
CREATE_FAILED
```

AWS reported the following error:

```text
UnauthorizedOperation

ec2:DescribeAvailabilityZones

User:
arn:aws:sts::761018849945:assumed-role/devops-nodes-eks-node-group
```

The EBS CSI Driver was attempting to use the EKS worker node IAM role instead of a dedicated IAM role.

Because the node role lacked the required permissions, the driver failed to start and entered a CrashLoopBackOff state.

---

# Root Cause Analysis

The EKS Add-on was initially configured as:

```hcl
aws-ebs-csi-driver = {
  most_recent = true
}
```

The configuration enabled the add-on but did not assign a dedicated IAM role.

As a result:

```text
No IRSA Configuration
      ↓
Driver Used Node Group IAM Role
      ↓
Missing Permissions
      ↓
UnauthorizedOperation Errors
      ↓
Addon Creation Failed
```

The missing component was IAM Roles for Service Accounts (IRSA).

---

# Troubleshooting Process

## Step 1 – Verify Cluster Health

Verified cluster functionality:

```bash
kubectl get nodes
```

Result:

```text
STATUS = Ready
```

This confirmed that the cluster and worker nodes were healthy.

---

## Step 2 – Verify Add-on Status

Checked add-on health:

```bash
aws eks describe-addon \
  --cluster-name devops-cluster \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1
```

Result:

```text
CREATE_FAILED
```

The logs indicated IAM permission failures.

---

## Step 3 – Verify OIDC Provider

Verified that the OIDC provider had been successfully created:

```bash
terraform state show \
module.eks[0].module.eks.aws_iam_openid_connect_provider.oidc_provider[0]
```

Result:

```text
OIDC Provider Present
```

This confirmed that IRSA could be implemented.

---

## Step 4 – Verify EKS Access Entries

Checked EKS access entries:

```bash
aws eks list-access-entries \
  --cluster-name devops-cluster
```

Verified:

* Jenkins Role
* Terraform Deployer Role
* Node Group Role

Cluster authentication was functioning correctly.

---

# Solution Implementation

## Step 1 – Create a Dedicated IRSA Role

Created a dedicated IAM role:

```text
eks-ebs-csi-driver-role
```

Configured trust relationship:

```text
sts:AssumeRoleWithWebIdentity
```

Restricted to:

```text
system:serviceaccount:kube-system:ebs-csi-controller-sa
```

This ensured that only the EBS CSI Driver could assume the role.

---

## Step 2 – Attach AWS Managed Policy

Attached:

```text
AmazonEBSCSIDriverPolicy
```

The policy grants permissions including:

* ec2:CreateVolume
* ec2:DeleteVolume
* ec2:AttachVolume
* ec2:DetachVolume
* ec2:DescribeVolumes
* ec2:DescribeInstances
* ec2:DescribeAvailabilityZones

These permissions are required for dynamic EBS provisioning.

---

## Step 3 – Update EKS Add-on Configuration

Updated Terraform configuration:

```hcl
aws-ebs-csi-driver = {

  most_recent = true

  service_account_role_arn =
    aws_iam_role.ebs_csi_driver.arn
}
```

This enabled IAM Roles for Service Accounts (IRSA).

---

## Step 4 – Remove Failed Add-on

Deleted the failed add-on:

```bash
aws eks delete-addon \
  --cluster-name devops-cluster \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1
```

---

## Step 5 – Deploy IRSA and Add-on

Executed a targeted Terraform deployment to avoid impacting Jenkins and other infrastructure.

Resources deployed:

* EBS CSI IAM Role
* EBS CSI Policy Attachment
* EBS CSI Add-on

---

# Validation

Verified add-on status:

```bash
aws eks describe-addon \
  --cluster-name devops-cluster \
  --addon-name aws-ebs-csi-driver \
  --region us-east-1 \
  --query "addon.status"
```

Result:

```text
ACTIVE
```

Verified node health:

```bash
kubectl get nodes
```

Result:

```text
STATUS = Ready
```

Verified Kubernetes access:

```bash
kubectl config current-context
```

Verified Terraform role access:

```bash
aws sts get-caller-identity --profile terraform
```

Result:

```text
assumed-role/terraform-deployer-role
```

---

# Final Architecture

```text
Amazon EKS Cluster
│
├── Managed Node Group
│
├── OIDC Provider
│
├── IAM Role for Service Account (IRSA)
│
├── AmazonEBSCSIDriverPolicy
│
└── EBS CSI Driver
      │
      ├── Create EBS Volumes
      ├── Attach EBS Volumes
      ├── Mount Volumes
      ├── Detach Volumes
      └── Delete EBS Volumes
```

---

# Key Lessons Learned

1. EKS clusters can operate without the EBS CSI Driver.
2. Stateful workloads require persistent storage provisioning.
3. OIDC is a prerequisite for IAM Roles for Service Accounts (IRSA).
4. AWS-managed add-ons should use dedicated IAM roles instead of node IAM roles.
5. IRSA follows the principle of least privilege and is the AWS-recommended security model.
6. Targeted Terraform deployments help prevent unintended infrastructure modifications during troubleshooting.
7. Understanding the difference between cluster functionality and workload requirements is critical when troubleshooting Kubernetes environments.

---

# Project Outcome

Successfully implemented the Amazon EBS CSI Driver using IAM Roles for Service Accounts (IRSA) within an Amazon EKS cluster.

While the EKS cluster itself was already operational, the implementation enabled dynamic persistent storage provisioning for stateful workloads.

The platform now supports:

* Dynamic EBS Volume Provisioning
* Persistent Volume Claims (PVCs)
* Stateful Kubernetes Applications
* Secure IAM Authentication through IRSA
* AWS-Managed EKS Add-ons
* Production-Ready Kubernetes Storage Architecture

This implementation provides the storage foundation required for future deployment of Jenkins, PostgreSQL, Prometheus, Grafana, ArgoCD, SonarQube, Elasticsearch, Loki, RabbitMQ, and other enterprise applications running on Amazon EKS.
