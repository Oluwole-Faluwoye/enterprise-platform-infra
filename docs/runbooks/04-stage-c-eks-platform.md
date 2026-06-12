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

GitHub

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

GitHub

↓

Jenkins

↓

Docker

↓

EKS

Applications become portable, scalable, resilient, and cloud-native.

---

# High-Level Architecture

## Stage A – Infrastructure Foundation

Developer

↓

GitHub

↓

Terraform

↓

AWS

Deliverables:

* VPC
* Networking
* IAM
* ECR
* EC2
* Storage

---

## Stage B – Automation Platform

Developer

↓

GitHub

↓

GitHub Webhook

↓

Jenkins

↓

SonarQube

↓

AWS

Deliverables:

* Jenkins
* SonarQube
* CI/CD Pipelines
* Security Scanning
* Infrastructure Automation

---

## Stage C – Enterprise Kubernetes Platform

Developer

↓

GitHub

↓

GitHub Webhook

↓

Jenkins

↓

Assume Terraform Role

↓

Terraform Validation

↓

tfsec Security Scan

↓

Checkov Compliance Scan

↓

Terraform Plan

↓

Manual Approval

↓

Terraform Apply

↓

AWS EKS

↓

Kubernetes Platform

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

# Terraform Architecture

## Repository Structure

```text
enterprise-platform-infra/
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
└── modules/
    ├── networking/
    ├── ecr/
    ├── iam/
    ├── jenkins/
    └── eks/
```

---

## Why This Architecture Was Chosen

The environments directory contains environment-specific configuration.

The modules directory contains reusable infrastructure components.

Benefits:

* Reusable infrastructure code
* Reduced duplication
* Easier maintenance
* Multi-environment support
* Enterprise Terraform best practice

Future environments can be added without modifying module code:

```text
environments/
├── dev
├── stage
└── prod
```

---

# Jenkins Terraform Pipeline Design

Infrastructure deployments are executed through Jenkins.

Pipeline Stages:

1. Checkout Source Code
2. Assume Terraform Deployment Role
3. Terraform Format Validation
4. Terraform Initialization
5. Terraform Validation
6. tfsec Security Scan
7. Checkov Compliance Scan
8. Terraform Plan
9. Archive Plan
10. Manual Approval
11. Terraform Apply

---

# Why Terraform Commands Execute From environments/dev

The Terraform root module is located inside:

```text
environments/dev
```

while infrastructure modules reside inside:

```text
modules/
```

For this reason Jenkins executes Terraform commands from:

```groovy
dir("environments/${TF_ENV}")
```

This ensures Terraform can correctly locate:

* main.tf
* providers.tf
* variables.tf
* outputs.tf

and properly reference reusable modules.

Without this configuration Terraform cannot locate the root module and infrastructure planning fails.

---

# Terraform Role Assumption

Jenkins does not use long-lived AWS credentials.

Instead, Jenkins assumes an IAM deployment role using AWS STS.

Flow:

Jenkins

↓

AWS STS

↓

terraform-deployer-role

↓

Temporary Credentials

↓

Terraform Deployment

Benefits:

* Improved security
* No static AWS keys
* Least privilege access
* Enterprise IAM best practice

---

# Configuration Management

Environment-specific values are separated from infrastructure code.

Examples:

* key_name
* home_ip

Configuration values are stored in:

```text
terraform.tfvars
```

The file is excluded from Git source control.

Benefits:

* Prevents sensitive information from being committed
* Supports environment-specific deployments
* Aligns with enterprise Infrastructure as Code practices

---

# Infrastructure Security Validation

Before any infrastructure changes are applied, Terraform code is automatically scanned.

## tfsec

Purpose:

Terraform security analysis.

Checks:

* Public exposure risks
* Insecure configurations
* Security group issues
* Encryption violations

---

## Checkov

Purpose:

Infrastructure compliance validation.

Checks:

* AWS best practices
* CIS benchmark recommendations
* Terraform policy compliance

Infrastructure changes must pass both scanners before deployment can continue.

---

# Enterprise Design Decisions

---

## Why Amazon EKS

Chosen:

Amazon Elastic Kubernetes Service (EKS)

Reasons:

* Managed Kubernetes Control Plane
* High Availability
* AWS Integration
* Enterprise Adoption
* Reduced Operational Overhead
* Production-Ready

Alternatives Considered:

* Self-Managed Kubernetes
* Kops
* ECS

Rejected Because:

Higher operational burden and lower industry demand.

---

## Why Private Worker Nodes

Chosen:

Private Subnets

Architecture:

Public Subnets

↓

Internet Gateway

↓

NAT Gateway

↓

Private Subnets

↓

EKS Worker Nodes

Purpose:

Prevent direct internet exposure.

Benefits:

* Improved Security
* Reduced Attack Surface
* Enterprise Best Practice

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

* Fine-Grained Permissions
* No Static AWS Credentials
* Industry Standard

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

* Automatic Updates
* Simplified Operations
* AWS Support
* Easier Scaling

Rejected:

Self-Managed Worker Nodes

Reason:

Additional maintenance burden.

---

# EKS Deployment Flow

Terraform Modules

↓

Environment Configuration

↓

Terraform Plan

↓

Terraform Apply

↓

AWS EKS

↓

Managed Node Groups

↓

Private Subnets

↓

Kubernetes Cluster

The EKS platform is provisioned entirely through reusable Terraform modules.

This approach ensures infrastructure remains version-controlled, repeatable, auditable, and fully automated.

---

# Environment Configuration

Example:

```hcl
enable_ecr         = true
enable_jenkins     = true
enable_eks         = true
enable_nat_gateway = true

key_name = "enterprise-platform-key"

home_ip = "x.x.x.x/32"
```
--------------------------------------------------------------------------
To implement the Jenkins Parameter so that you do not commit sensitive values like HomeIP and key name 


Save them as Jenkins Parameter 

Jenkins Parameters

Go to:

Infrastructure-Pipeline
↓
Configure
↓
This project is parameterized

Add:

String Parameter
Name:
KEY_NAME

Default:
us-east-1-key
String Parameter
Name:
HOME_IP

Default:
174.2.8.121/32
Add Create tfvars Stage

--------------------------------------------------------
In your Jenkinsfile Immediately before:

stage('Terraform Init')

add:

 stage('Create Runtime tfvars') {

            steps {

                dir("environments/${TF_ENV}") {

                    writeFile(

                        file: 'terraform.tfvars',

                        text: """
key_name = "${params.KEY_NAME}"

home_ip = "${params.HOME_IP}"
"""
                    )

                    sh '''

                    echo "Generated terraform.tfvars"

                    cat terraform.tfvars

                    '''
                }
            }
        }


--------------------------------------------------------------------------------
Also ensure that you have dev.auto.tfvars where you keep all your tfvars values 

dev.auto.tfvars : 

region = "us-east-1"

enable_ecr         = true
enable_jenkins     = true
enable_eks         = true
enable_nat_gateway = true

vpc_name = "devops-vpc"
vpc_cidr = "10.0.0.0/16"

azs = [
  "us-east-1a",
  "us-east-1b"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]


---

# Post Deployment Validation

## Verify Cluster

```bash
aws eks list-clusters
```

Expected:

```text
enterprise-platform
```

---

## Verify Node Groups

```bash
aws eks list-nodegroups \
--cluster-name enterprise-platform
```

Expected:

```text
managed-node-group
```

---

## Configure kubectl

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name enterprise-platform
```

---

## Verify Cluster Access

```bash
kubectl get nodes
```

Expected:

```text
STATUS = Ready
```

---

## Verify Namespaces

```bash
kubectl get namespaces
```

Expected:

* default
* kube-system
* kube-public

---

## Verify Pods

```bash
kubectl get pods -A
```

Expected:

System Pods Running

---

# Security Validation

## Verify Nodes Are Private

AWS Console

EKS Nodes

Expected:

* Private Subnets
* No Public IP

---

## Verify OIDC

```bash
aws eks describe-cluster \
--name enterprise-platform
```

Expected:

OIDC Issuer Present

---

## Verify IAM Authentication

```bash
kubectl auth can-i get pods
```

Expected:

```text
yes
```

---

# Troubleshooting

## Cluster Not Found

```bash
aws eks list-clusters
```

Verify Terraform deployment completed successfully.

---

## kubectl Access Denied

Run:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name enterprise-platform
```

---

## Nodes Not Joining

Check:

```bash
aws eks describe-nodegroup
```

Check:

```bash
kubectl get nodes
```

---

## Pods Pending

Check:

```bash
kubectl describe pod POD_NAME
```

Check:

```bash
kubectl get events
```

---

## OIDC Failure

Verify:

```bash
aws iam list-open-id-connect-providers
```

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

✓ Security Scanning Operational

✓ Cluster Ready For GitOps

---

# Deliverables

## Infrastructure

* EKS Cluster
* Managed Node Groups
* OIDC Provider
* NAT Gateway
* Security Groups

## Platform

* Kubernetes Control Plane
* Kubernetes Worker Nodes

## Security

* Private Worker Nodes
* IAM Roles for Service Accounts
* OIDC Integration
* tfsec Security Validation
* Checkov Compliance Validation

## Operations

* kubectl Access
* Jenkins Integration
* Automated Terraform Deployment
* Cluster Monitoring Ready

---

# Why This Stage Matters

This stage creates the platform where all future workloads will run.

Without Stage C:

Applications have nowhere to deploy.

With Stage C:

Applications can be deployed using:

* Kubernetes
* Helm
* ArgoCD
* Prometheus
* Grafana
* GitOps Workflows
* Future Enterprise Tooling

---

# Next Stage

## Stage D – Enterprise GitOps Platform

Components:

* ArgoCD
* GitOps Repository
* Helm Values
* Application Definitions
* Automated Synchronization

Outcome:

Deployment ownership moves from Jenkins to ArgoCD, establishing a true GitOps workflow.
