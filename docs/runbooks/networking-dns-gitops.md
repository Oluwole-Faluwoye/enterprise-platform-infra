Sprint 8 – Networking, DNS, GitOps Automation & Production Platform
Overview

Sprint 8 focused on transforming the platform from an infrastructure-only deployment into a production-ready cloud platform.

The major objectives were:

Introduce public networking
Automate DNS management
Introduce ACM certificates
Deploy AWS Load Balancer Controller
Deploy ExternalDNS
Complete IAM Roles for Service Accounts (IRSA)
Improve the Infrastructure Pipeline
Automate GitOps configuration updates
Prepare the platform for fully automated deployments
1. Route53 Integration
Objective

Provide AWS-native DNS management for the platform.

Implemented:

Route53 Hosted Zone module
Hosted Zone outputs
Name Server outputs
Hosted Zone ID output

Terraform now provisions:

Hosted Zone
DNS Validation Records
Future Application Records

Outputs include:

hosted_zone_id

hosted_zone_name_servers
2. Domain Strategy

Original plan:

ledgari.com

Issue:

The domain is already used for GitHub Pages.

Changing nameservers would break the existing website.

Decision:

Purchase a dedicated domain.

Final domain:

dreammyles.online

Benefits:

Completely isolated
No production impact
Full Route53 automation
3. DNS Architecture

Architecture:

Namecheap

↓

dreammyles.online

↓

Custom Nameservers

↓

Route53 Hosted Zone

↓

ExternalDNS

↓

AWS Load Balancer

↓

Applications

Namecheap only stores the delegation.

Route53 owns every DNS record afterwards.

4. ACM Integration

Implemented:

Terraform ACM module

Creates:

*.dev.dreammyles.online

dev.dreammyles.online

Validation:

DNS

Validation records are created automatically using Route53.

Outputs:

certificate_arn

certificate_domain

Certificate lifecycle:

Create

↓

DNS Validation

↓

Issued

↓

Referenced by ALB
5. IAM Roles for Service Accounts (IRSA)

Completed controllers:

External Secrets

Role

Policy

Trust Policy

Outputs

ExternalDNS

Role

Policy

Trust Policy

Outputs

Permissions:

route53:ChangeResourceRecordSets

route53:ListHostedZones

route53:ListResourceRecordSets

Hosted Zone access restricted to:

dreammyles.online

using:

hosted_zone_id

instead of:

hostedzone/*

Following the Principle of Least Privilege.

AWS Load Balancer Controller

Role

Policy

Trust Policy

Outputs

Permissions include:

ELB
Target Groups
Security Groups
Listener Rules
Tags
6. Terraform Modules

Completed Modules:

eks

route53

acm

iam-irsa

secrets-manager

Terraform validation:

terraform init

terraform validate

terraform plan

Status:

63 resources

0 changes

0 destroy

Infrastructure ready for deployment.

7. GitOps Architecture

GitOps Repository structure:

applications/

charts/

docs/

platform-services/

root-app.yaml

Applications include:

External Secrets

AWS Load Balancer Controller

ExternalDNS

Monitoring Assets

Prometheus

Loki

Promtail

Networking

Auth Service
8. Sync Wave Strategy

Final ordering:

-2 Storage

-1 External Secrets

0 External Secrets Platform

1 AWS Load Balancer Controller

2 ExternalDNS

3 Monitoring Assets

4 Prometheus Stack

5 Loki

6 Promtail

7 Networking

8 Auth Service

Ensures dependencies are installed before workloads.

9. Networking Chart

Networking chart introduced.

Responsibilities:

Shared ALB

HTTPS

Host routing

Ingress resources

Future application routing

Applications:

api.dev.dreammyles.online

grafana.dev.dreammyles.online

argocd.dev.dreammyles.online
10. ExternalDNS

Configured:

Provider

AWS

Policy

Sync

Registry

TXT

TXT Owner

enterprise-platform

Sources

Ingress

Service

Domain Filter:

dreammyles.online

Deployment:

ArgoCD

Authentication:

IRSA

11. AWS Load Balancer Controller

Configured:

IRSA

ServiceMonitor

Replica Count

PDB

Logging

ALB Controller is deployed through ArgoCD.

Not through Jenkins.

12. Jenkins Infrastructure Pipeline Improvements

Pipeline Responsibilities:

Terraform Apply

Read Terraform Outputs

Configure kubectl

Install ArgoCD

Checkout GitOps

Update GitOps Configuration

Configure Repository Secret

Bootstrap GitOps

Verify GitOps

13. Read Terraform Outputs Stage

New stage:

Read Terraform Outputs

Reads:

cluster_name

certificate_arn

external_dns_role_arn

aws_load_balancer_controller_role_arn

hosted_zone_id

Values are stored as Jenkins environment variables.

14. Automatic GitOps Updates

New stage:

Update GitOps Configuration

Automatically updates:

ExternalDNS:

eks.amazonaws.com/role-arn

AWS Load Balancer Controller:

eks.amazonaws.com/role-arn

Networking:

alb.certificateArn

Then:

git add

git commit

git push

only if changes exist.

15. GitOps Responsibilities

Infrastructure Pipeline owns:

Terraform

AWS Infrastructure

Outputs

GitOps updates

ArgoCD bootstrap

ArgoCD owns:

External Secrets

ExternalDNS

AWS Load Balancer Controller

Prometheus

Grafana

Alertmanager

Loki

Promtail

Networking

Auth Service

The Infrastructure Pipeline does not deploy application workloads. Its responsibility is to prepare the infrastructure and bootstrap Argo CD. From that point onward, Argo CD continuously reconciles the desired state defined in the GitOps repository.

16. Production Deployment Flow
Developer

↓

Push Infrastructure Repository

↓

Jenkins

↓

Terraform Init

↓

Terraform Validate

↓

Security Scans

↓

Terraform Plan

↓

Manual Approval

↓

Terraform Apply

↓

Read Terraform Outputs

↓

Configure kubectl

↓

Install ArgoCD

↓

Checkout GitOps Repository

↓

Update GitOps Configuration

↓

Configure Repository Secret

↓

Bootstrap root-app

↓

ArgoCD Synchronization

↓

Controllers Installed

↓

Networking Created

↓

Applications Deployed

↓

Platform Available

17. Security Improvements

Implemented:

IRSA for all AWS controllers
Principle of Least Privilege
Hosted Zone–scoped Route53 permissions
Secrets stored in AWS Secrets Manager
No long-lived AWS credentials inside Kubernetes
DNS validation for ACM certificates
GitOps repository authentication using an SSH private key stored in AWS Secrets Manager
18. Architectural Decisions

The following design decisions were made:

Use Route53 for authoritative DNS while keeping the domain registered with Namecheap.
Use AWS ACM for public TLS termination instead of cert-manager for internet-facing services.
Keep the VPC managed by the bootstrap Terraform state and consume it through terraform_remote_state.
Keep IAM controller resources consolidated in the existing iam-irsa module rather than refactoring late in the project.
Use Jenkins to inject infrastructure-derived values into the GitOps repository before Argo CD reconciliation.
Keep application deployment responsibility entirely within Argo CD.

19. Current Platform Status
Component	Status
Bootstrap Infrastructure	✅ Complete
VPC	✅ Complete
EKS	✅ Complete
Terraform Modules	✅ Complete
Secrets Manager	✅ Complete
IAM IRSA	✅ Complete
Route53	✅ Complete
ACM	✅ Complete
Jenkins Infrastructure Pipeline	✅ Enhanced
GitOps Repository	✅ Structured
External Secrets	✅ Ready
ExternalDNS	✅ Ready
AWS Load Balancer Controller	✅ Ready
Monitoring Stack	✅ Ready
Networking Chart	✅ Ready
Auth Service	✅ Ready
End-to-End Deployment	⏳ Pending pipeline execution

20. Lessons Learned
Keep infrastructure ownership clear: Terraform provisions cloud resources, while Argo CD manages Kubernetes workloads.
Use Terraform outputs as the single source of truth for infrastructure-generated values such as IAM role ARNs and certificate ARNs.
Automate GitOps configuration updates in the infrastructure pipeline to eliminate manual edits.
Separate public DNS registration (Namecheap) from authoritative DNS management (Route53) for flexibility.
Delay non-essential refactoring until after functionality is complete to avoid unnecessary deployment risk.

This document represents the complete gap from the end of Sprint 7 through the current state of Sprint 8 and provides a comprehensive record of the architectural decisions, implementation work, and deployment workflow you've built. It should serve as the reference point before you execute the infrastructure pipeline and begin end-to-end validation.

-------------------------------------------------------------------------------------------------------

read this as well 

# Sprint 8 – Infrastructure Automation, DNS, TLS & GitOps Integration

## Overview

Sprint 8 focused on completing the production infrastructure layer and integrating Terraform with GitOps.

The primary objective was to ensure that infrastructure is provisioned through Terraform and Jenkins, while Kubernetes resources are managed exclusively by Argo CD.

This sprint completed:

- Route53 DNS management
- ACM wildcard certificate automation
- IAM Roles for Service Accounts (IRSA)
- ExternalDNS integration
- AWS Load Balancer Controller integration
- Infrastructure → GitOps automation
- Pipeline improvements
- Production deployment workflow

---

# Final Architecture

```

Developer
↓

Git Push

↓

Jenkins Infrastructure Pipeline

↓

Terraform Apply

↓

Read Terraform Outputs

↓

Update GitOps Repository

↓

Commit GitOps Repository

↓

Install ArgoCD

↓

Bootstrap Root Application

↓

ArgoCD Sync

↓

External Secrets

↓

AWS Load Balancer Controller

↓

ExternalDNS

↓

Networking

↓

Monitoring

↓

Applications

```

Terraform is responsible only for AWS infrastructure.

ArgoCD is responsible only for Kubernetes resources.

---

# Infrastructure Ownership

Terraform owns:

- VPC (Bootstrap)
- IAM
- EKS
- Route53
- ACM
- Secrets Manager
- OIDC Provider
- IRSA Roles

ArgoCD owns:

- AWS Load Balancer Controller
- ExternalDNS
- External Secrets
- Prometheus
- Grafana
- Alertmanager
- Loki
- Promtail
- Auth Service
- Networking Resources

This separation prevents configuration drift and follows GitOps best practices.

---

# Route53

## Hosted Zone

Terraform creates the hosted zone.

```

dreammyles.online

```

Outputs:

- Hosted Zone ID
- Name Servers

The only manual step required is changing the Namecheap nameservers to the Route53 nameservers.

Once delegated, Route53 becomes authoritative.

---

# ACM

Terraform provisions a wildcard certificate.

```

*.dev.dreammyles.online

```

Subject Alternative Name

```

dev.dreammyles.online

```

Validation Method

DNS Validation

Terraform automatically creates:

- Route53 Validation Records
- ACM Certificate Validation

No manual ACM validation is required.

---

# IAM Roles for Service Accounts (IRSA)

Implemented:

## External Secrets

Purpose

Read AWS Secrets Manager.

Permissions

- GetSecretValue
- DescribeSecret
- ListSecretVersionIds

---

## ExternalDNS

Purpose

Manage Route53 records.

Permissions

- ChangeResourceRecordSets
- ListHostedZones
- ListResourceRecordSets

Scope

Restricted to the project Hosted Zone.

---

## AWS Load Balancer Controller

Purpose

Provision:

- ALBs
- Target Groups
- Security Groups
- Listener Rules

Using AWS APIs.

---

# Jenkins Pipeline Improvements

Infrastructure Pipeline stages

Checkout

↓

Assume Terraform Role

↓

Terraform Format

↓

Terraform Init

↓

Terraform Validate

↓

tfsec

↓

Checkov

↓

Terraform Plan

↓

Manual Approval

↓

Terraform Apply

↓

Read Terraform Outputs

↓

Validate Cluster

↓

Configure kubectl

↓

Install ArgoCD

↓

Checkout GitOps Repository

↓

Update GitOps Configuration

↓

Configure Repository Secret

↓

Bootstrap Root App

↓

Verify Deployment

---

# Read Terraform Outputs Stage

The pipeline now stores Terraform outputs as Jenkins environment variables.

Outputs collected

- Cluster Name
- ExternalDNS Role ARN
- AWS Load Balancer Controller Role ARN
- ACM Certificate ARN
- Hosted Zone ID

These values are used later during GitOps configuration.

---

# GitOps Configuration Update

Rather than hardcoding cloud resources in Git, Jenkins automatically injects infrastructure values after Terraform Apply.

Updated automatically

ExternalDNS

```

serviceAccount.annotations.eks.amazonaws.com/role-arn

```

AWS Load Balancer Controller

```

serviceAccount.annotations.eks.amazonaws.com/role-arn

```

Networking

```

alb.certificateArn

```

Future

Application image tags continue to be updated by the application deployment pipeline.

---

# Why Dynamic Updates?

Infrastructure creates resources whose identifiers are not known until runtime.

Examples

IAM Role ARN

```

arn:aws:iam::761018849945:role/enterprise-platform-dev-external-dns

```

Certificate ARN

```

arn:aws:acm:...

```

These values should never be manually copied into Git.

The pipeline retrieves them automatically using Terraform outputs.

---

# ExternalDNS

Configured with

Provider

AWS

Registry

TXT

Policy

Sync

Domain Filter

```

dreammyles.online

```

Sources

- Ingress
- Services

Service Account

Uses IRSA.

No static AWS credentials.

---

# AWS Load Balancer Controller

Configured using

IRSA

Cluster Name

Terraform Output

Certificate ARN

Pipeline injected

The controller provisions internet-facing ALBs from Kubernetes Ingress resources.

---

# Networking

Networking is entirely GitOps managed.

ArgoCD deploys:

Ingresses

↓

AWS Load Balancer Controller

↓

Application Load Balancer

↓

ExternalDNS

↓

Route53

↓

HTTPS

---

# DNS Flow

Developer

↓

Ingress

↓

ALB Controller

↓

ALB

↓

ExternalDNS

↓

Route53

↓

DNS Record

↓

Client

No Route53 records are manually created.

Everything after Hosted Zone creation is automated.

---

# TLS Flow

Terraform

↓

ACM Certificate

↓

Pipeline

↓

Networking values.yaml

↓

ArgoCD

↓

Ingress

↓

ALB

↓

HTTPS

---

# GitOps Repository

Applications

- External Secrets
- External Secrets Platform
- AWS Load Balancer Controller
- ExternalDNS
- Monitoring Assets
- Prometheus
- Loki
- Promtail
- Networking
- Auth Service

Deployment order controlled using Sync Waves.

---

# Sync Waves

Wave -2

Storage

Wave -1

External Secrets

Wave 0

External Secrets Platform

Wave 1

AWS Load Balancer Controller

Wave 2

ExternalDNS

Wave 3

Monitoring Assets

Wave 4

Prometheus Stack

Wave 5

Loki

Wave 6

Promtail

Wave 7

Networking

Wave 8

Auth Service

---

# Security Improvements

Implemented

- IAM Roles for Service Accounts
- No AWS Access Keys
- Principle of Least Privilege
- DNS Validation
- Automatic Certificate Rotation
- Infrastructure as Code
- GitOps
- tfsec
- Checkov
- Manual Approval before Apply

---

# Responsibilities

Terraform

Creates infrastructure.

Jenkins

Deploys infrastructure.

Reads Terraform Outputs.

Updates GitOps.

Bootstraps ArgoCD.

ArgoCD

Deploys Kubernetes resources.

Maintains desired state.

Kubernetes Controllers

Provision AWS resources.

AWS

Provides cloud infrastructure.

---

# Lessons Learned

Infrastructure and workloads should remain separate.

Terraform owns AWS resources.

GitOps owns Kubernetes resources.

Runtime-generated values should never be manually copied into Git.

Instead, CI/CD should retrieve infrastructure outputs and update GitOps automatically.

This approach minimizes configuration drift, improves repeatability, and supports fully automated deployments.

---

# Sprint 8 Completion Checklist

Completed

- Route53
- ACM
- Wildcard Certificate
- DNS Validation
- IRSA
- ExternalDNS IAM
- AWS Load Balancer Controller IAM
- Jenkins Pipeline Automation
- Terraform Outputs
- GitOps Configuration Injection
- Dynamic Certificate Injection
- Dynamic IAM Injection
- Dynamic GitOps Updates

Sprint 8 Status

COMPLETE

Next Sprint

Sprint 9

Platform Deployment, Validation & Production Hardening