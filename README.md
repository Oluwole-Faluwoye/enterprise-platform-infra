# Enterprise Cloud-Native Platform Engineering Project

## Overview

This project demonstrates the design and implementation of a production-inspired cloud-native platform on AWS using Infrastructure as Code, Kubernetes, CI/CD, GitOps, observability, and DevSecOps practices.

The platform simulates real-world enterprise environments used by SaaS, fintech, healthcare, and government organizations.

---

## Architecture

### Infrastructure

* AWS VPC
* Public and Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables
* Security Groups

### Platform

* Amazon EKS
* Helm
* Jenkins
* Docker
* Amazon ECR

### DevSecOps

* SonarQube
* Trivy

### Future Enhancements

* ArgoCD
* Prometheus
* Grafana
* Loki
* OpenTelemetry
* HPA
* Cluster Autoscaler

---

## Repository Structure

docs/
terraform/
diagrams/

---

## Documentation

| Module            | Description                        |
| ----------------- | ---------------------------------- |
| Terraform Backend | docs/01-terraform-backend.md       |
| Networking        | docs/02-networking-foundation.md   |
| EKS               | docs/03-eks-architecture.md        |
| Kubernetes        | docs/04-kubernetes-fundamentals.md |

---

## Key Skills Demonstrated

* AWS Cloud Engineering
* Terraform
* Kubernetes
* DevOps
* CI/CD
* Infrastructure as Code
* Containerization
* Cloud Security
* Platform Engineering
* Site Reliability Engineering


## Security Architecture

This project follows the Principle of Least Privilege by separating CI/CD permissions from infrastructure provisioning permissions.

Jenkins does not receive broad AWS administrative permissions directly.

Instead, Jenkins runs using a restricted EC2 role and assumes a dedicated deployment role whenever Terraform needs to provision infrastructure.

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
            └── Terraform Managed Resources
```

This design reduces the blast radius of a compromised Jenkins server and aligns with enterprise DevOps and Platform Engineering security practices.

For a detailed explanation, see:

```text
docs/JENKINS_ASSUME_ROLE_ARCHITECTURE.md
```



## Access Controls

The Jenkins EC2 instance is deployed in a public subnet for administrative access.

Security controls include:

- SSH access restricted to trusted administrator IP addresses
- AWS Systems Manager Session Manager enabled
- IMDSv2 enforced
- Encrypted root and data volumes
- Least-privilege IAM design using STS AssumeRole

Commit
terraform.tfvars.example

Example:

home_ip = "YOUR_PUBLIC_IP/32"
Do NOT commit
terraform.tfvars

which contains:

home_ip = "104.xxx.xxx.xxx/32"

(or whatever your actual IP is).
