# Amazon Elastic Container Registry (ECR)

## Overview

Amazon ECR is AWS's managed container registry service.

It stores Docker images used by Kubernetes workloads.

---

# Purpose

Provide:

* Secure image storage
* Image versioning
* IAM integration
* Private repositories

for containerized workloads.

---

# Platform Flow

Developer
↓
Jenkins
↓
Docker Build
↓
Amazon ECR
↓
Amazon EKS

---

# Why ECR Exists

Kubernetes cannot deploy source code.

Kubernetes deploys container images.

ECR stores those images.

---

# Image Lifecycle

Source Code
↓
Maven Build
↓
Docker Build
↓
Image
↓
ECR
↓
EKS Pod

---

# Common Commands

Login:

```bash
aws ecr get-login-password \
| docker login \
--username AWS \
--password-stdin <account>.dkr.ecr.<region>.amazonaws.com
```

Tag:

```bash
docker tag auth-service:v1 \
<account>.dkr.ecr.<region>.amazonaws.com/auth-service:v1
```

Push:

```bash
docker push \
<account>.dkr.ecr.<region>.amazonaws.com/auth-service:v1
```

---

# Benefits

* Managed service
* Highly available
* Secure
* Integrated with IAM

---

# Common Issues

* Authentication failures
* Missing IAM permissions
* Incorrect repository names

---

# Interview Questions

Q: What is Amazon ECR?

A:

A managed container registry used to store and distribute Docker images.

Q: Why use ECR with EKS?

A:

EKS retrieves container images from ECR and deploys them as Kubernetes workloads.

---

# Concepts Learned

* Container Registry
* Docker Images
* Image Lifecycle
* ECR Authentication
* IAM Integration
