# Stage C – Enterprise Kubernetes Platform (EKS)

---

# Objective

The objective of Stage C is to deploy a production-grade Kubernetes platform on AWS using Amazon EKS.

This stage transforms the environment from a traditional infrastructure platform into a cloud-native platform capable of running enterprise workloads.

At the end of this stage, the platform will be capable of:

* Running microservices
* Running containerized workloads
* Scaling automatically
* Integrating with GitOps
* Supporting observability tooling
* Supporting future production deployments

---

# Why Stage C Exists

At this point:

Stage A created the infrastructure foundation.

Stage B created the automation platform.

Now we need a deployment platform.

Without Kubernetes:

Developer
↓
Jenkins
↓
Docker
↓
EC2

This approach becomes difficult to scale.

With Kubernetes:

Developer
↓
Jenkins
↓
Docker
↓
EKS

Applications become portable, scalable, resilient, and cloud-native.

---

# High-Level Architecture

Stage B

Developer
↓
GitHub
↓
Jenkins
↓
Terraform
↓
AWS

Stage C

Developer
↓
GitHub
↓
Jenkins
↓
Terraform
↓
EKS

Applications
↓
Pods
↓
Services
↓
Ingress
↓
Load Balancers

---

# Enterprise Design Decisions

---

## Why Amazon EKS

Chosen:

Amazon Elastic Kubernetes Service (EKS)

Reasons:

* Managed Kubernetes Control Plane
* High availability
* AWS integration
* Enterprise adoption
* Reduced operational overhead
* Production-ready

Alternatives Considered:

* Self-managed Kubernetes
* Kops
* ECS

Rejected Because:

Higher operational burden and lower industry demand.

---

## Why Private Worker Nodes

Chosen:

Private Subnets

Architecture:

Public Subnet

Internet Gateway

NAT Gateway

Private Subnets

EKS Worker Nodes

Purpose:

Prevent direct internet exposure.

Benefits:

* Improved security
* Reduced attack surface
* Enterprise best practice

Rejected:

Public Worker Nodes

Reason:

Increased exposure to internet threats.

---

## Why NAT Gateway

Chosen:

Enable outbound internet access for private worker nodes.

Without NAT:

Worker Nodes cannot:

* Pull container images
* Access AWS APIs
* Download packages
* Install updates

Architecture:

Private Node
↓
NAT Gateway
↓
Internet

---

## Why OIDC Provider

Chosen:

OIDC Identity Provider

Purpose:

Allow Kubernetes Service Accounts to assume IAM Roles.

Benefits:

* Fine-grained permissions
* No static AWS credentials
* Industry standard

Architecture:

Pod
↓
Service Account
↓
IAM Role
↓
AWS Service

---

## Why Managed Node Groups

Chosen:

EKS Managed Node Groups

Benefits:

* Automatic updates
* Simplified operations
* AWS support
* Easier scaling

Rejected:

Self-managed worker nodes

Reason:

Additional maintenance burden.

---

# Terraform Configuration

Enable Kubernetes Platform

terraform.tfvars

enable_ecr = true

enable_jenkins = true

enable_eks = true

enable_nat_gateway = true

---

# Infrastructure Components

---

## EKS Control Plane

Purpose:

Manage Kubernetes API.

Managed By:

AWS

High Availability:

Multi-AZ

---

## Managed Node Groups

Purpose:

Run workloads.

Location:

Private Subnets

Scaling:

Automatic

---

## OIDC Provider

Purpose:

IAM integration for workloads.

---

## NAT Gateway

Purpose:

Outbound internet connectivity.

---

## Security Groups

Purpose:

Secure cluster communication.

---

# Terraform Deployment Commands

Initialize

terraform init

Validate

terraform validate

Plan

terraform plan 
-var-file=environments/dev/terraform.tfvars

Deploy

terraform apply 
-var-file=environments/dev/terraform.tfvars

---

# Post Deployment Validation

---

## Verify Cluster

aws eks list-clusters

Expected:

enterprise-platform

---

## Verify Node Groups

aws eks list-nodegroups 
--cluster-name enterprise-platform

Expected:

managed-node-group

---

## Configure kubectl

aws eks update-kubeconfig 
--region us-east-1 
--name enterprise-platform

---

## Verify Cluster Access

kubectl get nodes

Expected:

STATUS = Ready

---

## Verify Namespaces

kubectl get namespaces

Expected:

default

kube-system

kube-public

---

## Verify Pods

kubectl get pods -A

Expected:

System Pods Running

---

# Security Validation

---

## Verify Nodes Are Private

AWS Console

EKS Nodes

Expected:

Private Subnets

No Public IP

---

## Verify OIDC

aws eks describe-cluster 
--name enterprise-platform

Expected:

OIDC Issuer Present

---

## Verify IAM Authentication

kubectl auth can-i get pods

Expected:

yes

---

# Troubleshooting

---

## Cluster Not Found

aws eks list-clusters

Verify Terraform deployment completed.

---

## kubectl Access Denied

Run:

aws eks update-kubeconfig 
--region us-east-1 
--name enterprise-platform

---

## Nodes Not Joining

Check:

aws eks describe-nodegroup

Check:

kubectl get nodes

---

## Pods Pending

Check:

kubectl describe pod POD_NAME

Check:

kubectl get events

---

## OIDC Failure

Verify:

aws iam list-open-id-connect-providers

---

# Stage Completion Criteria

Stage C is complete when:

✓ EKS Cluster Created

✓ Control Plane Healthy

✓ Managed Node Groups Running

✓ Worker Nodes Joined

✓ NAT Gateway Operational

✓ OIDC Provider Configured

✓ kubectl Access Working

✓ Nodes In Ready State

✓ Cluster Accessible From Jenkins

✓ Cluster Ready For GitOps

---

# Deliverables

Infrastructure

* EKS Cluster
* Managed Node Groups
* OIDC Provider
* NAT Gateway
* Security Groups

Platform

* Kubernetes Control Plane
* Kubernetes Worker Nodes

Security

* Private Worker Nodes
* IAM Roles For Service Accounts
* OIDC Integration

Operations

* kubectl Access
* Cluster Monitoring Ready

---

# Why This Stage Matters

This stage creates the platform where all future workloads will run.

Without Stage C:

Applications have nowhere to deploy.

With Stage C:

Applications can be deployed using Kubernetes, GitOps, Helm, ArgoCD, Prometheus, Grafana, and future enterprise tooling.

---

# Next Stage

Stage D – Enterprise GitOps Platform

Components:

* ArgoCD
* GitOps Repository
* Helm Values
* Application Definitions
* Automated Synchronization

Outcome:

Deployment ownership moves from Jenkins to ArgoCD, establishing a true GitOps workflow.
