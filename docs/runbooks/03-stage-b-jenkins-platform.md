# Stage B – Enterprise Jenkins Platform

---

# Objective

The objective of Stage B is to deploy a dedicated Platform Engineering server that serves as the automation engine for the entire platform.

This platform is responsible for:

* Infrastructure Automation
* Continuous Integration (CI)
* Security Scanning
* Container Image Delivery
* GitOps Repository Updates
* Platform Lifecycle Management

This stage establishes the foundation required before Kubernetes and GitOps can be introduced.

---

# Why Stage B Exists

Before deploying Kubernetes, there must be a platform capable of:

* Building applications
* Running tests
* Performing security scans
* Building container images
* Pushing images to ECR
* Managing infrastructure through Terraform

For this reason, Jenkins is deployed before EKS.

Architecture progression:

Stage A
↓
Foundation Infrastructure

Stage B
↓
Platform Automation Engine

Stage C
↓
Kubernetes Platform

Stage D
↓
GitOps Deployment Model

---

# High-Level Architecture

Current Architecture

Developer
↓
GitHub
↓
Jenkins
↓
Terraform
↓
AWS

Application Delivery

Developer
↓
GitHub
↓
Jenkins
↓
Build
↓
SonarQube
↓
Trivy
↓
ECR

Future Architecture

Developer
↓
GitHub
↓
Jenkins
↓
Build
↓
Test
↓
Security Scan
↓
Push Image
↓
Update GitOps Repository
↓
ArgoCD
↓
EKS

---

# Enterprise Design Decisions

## Why Jenkins Runs on EC2

Chosen:

Amazon EC2

Reasons:

* Full administrative control
* Custom Jenkins image support
* Docker socket access
* Easy AWS integration
* Supports Terraform automation
* Supports enterprise IAM controls

Alternatives Considered:

* ECS
* Fargate
* Kubernetes

Rejected Because:

Jenkins is responsible for creating the Kubernetes platform.

Kubernetes cannot bootstrap itself.

---

## Why Amazon Linux 2023

Chosen:

Amazon Linux 2023

Reasons:

* Current AWS recommended Linux distribution
* Longer support lifecycle
* Better security defaults
* Improved package management using DNF
* Future-proof platform

Rejected:

Amazon Linux 2

Reason:

Approaching end of support lifecycle.

---

## Why Dedicated EBS Storage

A dedicated EBS volume is attached to the Jenkins server.

Mount Point:

/data

Persistent Directories:

/data/jenkins

/data/sonarqube

Benefits:

* Jenkins survives EC2 replacement
* SonarQube survives EC2 replacement
* Disaster recovery capability
* Infrastructure rebuild capability
* Data separation from operating system

Without dedicated EBS:

Terraform destroy
↓
All Jenkins data lost

With dedicated EBS:

Terraform destroy
↓
EC2 removed
↓
Data preserved

---

## Why IMDSv2

Terraform Configuration:

metadata_options {

http_endpoint = "enabled"

http_tokens = "required"

}

Purpose:

* Protects against SSRF attacks
* AWS security best practice
* Enterprise compliance requirement

Benefits:

* Session-based metadata access
* Reduced attack surface
* More secure instance metadata retrieval

---

## Why SSH Is Restricted

Terraform Configuration:

ingress {

from_port = 22

to_port = 22

protocol = "tcp"

cidr_blocks = [var.home_ip]

}

Purpose:

Prevent internet-wide SSH access.

Rejected:

0.0.0.0/0

Reason:

Unnecessary exposure of management ports.

Only the administrator's IP address can access the server.


### Security

SSH:

Restricted to home IP  

NOTE : Always ensure to check your allowed_jenkins_Cidr and edit it in the ( terraform.tfvars file ) before running terraform apply

To  get your home Ip address run this on your browser : https://whatismyipaddress.com/



If your home_ip = "Your_home_IP/32"  isn't correct, you wont be able to SSH into the jenkins server as we have restricteed it to our home/ocal IP. 

In enterprise settings youd be using Bastion Host or VPN for a secure network
---

## Why Jenkins Uses AssumeRole

Security Architecture

Jenkins EC2 Role
↓
AssumeRole
↓
terraform-deployer-role

Purpose:

Apply the Principle of Least Privilege.

Benefits:

* Jenkins EC2 receives limited permissions
* Terraform receives elevated permissions only when needed
* Reduces blast radius during compromise
* Enterprise security pattern

Without AssumeRole:

Jenkins receives AdministratorAccess

With AssumeRole:

Jenkins receives minimal permissions

Terraform assumes elevated permissions only during deployment

---

# Jenkins Image Design

Repository:

761018849945.dkr.ecr.us-east-1.amazonaws.com/jenkins

Purpose:

Create a reusable enterprise Jenkins image.

---

## Included Tools

Docker CLI

Purpose:

Build and push container images.

AWS CLI v2

Purpose:

AWS authentication and ECR operations.

Terraform

Purpose:

Infrastructure deployment.

kubectl

Purpose:

Kubernetes management.

Helm

Purpose:

Kubernetes package management.

Git

Purpose:

Source code operations.

jq

Purpose:

JSON processing.

---

## Intentionally Excluded

Maven

Trivy

Sonar Scanner

Reason:

Enterprise platforms execute build tools inside disposable containers.

Example:

agent {

docker {

image 'maven:3.9-eclipse-temurin-21'

}

}

Benefits:

* Smaller Jenkins image
* Faster image rebuilds
* Reduced attack surface
* Easier upgrades
* Better version control

---

# Bootstrap Process

Terraform launches EC2.

Terraform
↓
EC2 Launch
↓
cloud-init
↓
setup.sh
↓
Install Docker
↓
Mount EBS
↓
Verify IAM
↓
Login ECR
↓
Pull Jenkins Image
↓
Pull SonarQube Image
↓
Start Containers
↓
Health Checks

---

Ensure youre in the directory your " terraform.tfvars"  is and run the following commands : 
then run the following commands

i.e you must be in environments/dev  

# Terraform Commands

Initialize Terraform

terraform init
---------------------------------
Validate Configuration

terraform validate
----------------------------------
Generate Execution Plan

terraform plan 
---------------------------------------
Deploy Infrastructure

terraform apply 

---------------------------------------------------------------------

If you ever want to delete the jenkins EC2 without touching the other resources 

Change : 

enable_jenkins = false   inside  your terraform.tfvars

and run 

terraform apply

Terraform will believe that the Jenkins EC2 is not meant to be in existence and it will delete it and preserve the other resources.

-----------------------------------------------------------
To Recreate Jenkins Platform

enable_jenkins = true

terraform apply 

------------------------------------------------------------

After Jenkins deploys successfully, SSH into Jenkins EC2:

# Bootstrap Validation

Verify EC2

aws ec2 describe-instances

Expected:

Running

---

Verify IAM

aws sts get-caller-identity

Expected:

jenkins-ec2-role

---

Verify Storage

df -h

Expected:

/data mounted

---

Verify Docker

docker ps

Expected:

jenkins

sonarqube

---

Verify ECR

aws ecr describe-repositories

Expected:

auth-service

jenkins

---

Verify Jenkins

http://PUBLIC-IP:8080

Expected:

Jenkins UI

---

Verify SonarQube

http://PUBLIC-IP:9000

Expected:

SonarQube UI

---

# Troubleshooting

## Cloud-Init Failure

Check:

sudo cloud-init status

Logs:

sudo tail -200 /var/log/cloud-init-output.log

---

## Docker Failure

sudo systemctl status docker

---

## Jenkins Failure

docker logs jenkins

---

## SonarQube Failure

docker logs sonarqube

---

## ECR Authentication Failure

aws sts get-caller-identity

aws ecr describe-repositories

---

## Storage Failure

df -h

mount | grep /data

---

# Stage B Completion Criteria

Stage B is complete when:

✓ Jenkins EC2 deployed

✓ Dedicated EBS mounted

✓ IAM role attached

✓ IMDSv2 enabled

✓ Jenkins image pulled from ECR

✓ SonarQube image deployed

✓ Jenkins accessible

✓ SonarQube accessible

✓ ECR access validated

✓ Terraform AssumeRole validated

✓ Bootstrap automation successful

---

# Deliverables

Infrastructure:

* Jenkins EC2
* Security Group
* IAM Role
* Instance Profile
* EBS Volume
* CloudWatch Log Group

Platform:

* Jenkins
* SonarQube

Security:

* IMDSv2
* Least Privilege IAM
* AssumeRole Model
* Restricted SSH Access

---

# Next Stage

Stage C – Enterprise Kubernetes Platform

Components:

* NAT Gateway
* EKS Control Plane
* Managed Node Groups
* OIDC Provider
* EKS Add-ons

Outcome:

Production-grade Kubernetes platform ready for GitOps deployment.




