# Runbook 01 - Local Development Tooling

## Objective

Prepare a local workstation for Cloud Engineering, DevOps Engineering, Platform Engineering, and Site Reliability Engineering activities.

This workstation is used to:

* Develop Spring Boot Applications
* Build Docker Images
* Manage AWS Resources
* Deploy Kubernetes Workloads
* Execute Terraform
* Manage CI/CD Pipelines

---

# Operating System

Windows 10

Shell:

Git Bash

IDE:

VS Code

---

# Java Installation

Purpose:

Required for Spring Boot development and Maven builds.

Verification:

```bash
java -version
```

Current Result:

```text
openjdk version "17.0.15"
```

Status:

✅ Installed

---

# Maven Installation

Purpose:

Build and package Java applications.

Verification:

```bash
mvn -version
```

Current Result:

```text
Apache Maven 3.9.9
```

Status:

✅ Installed

---

# Git Installation

Purpose:

Source Control Management.

Verification:

```bash
git --version
```

Expected:

```text
git version x.x.x
```

Status:

✅ Installed

---

# Visual Studio Code

Purpose:

Primary development environment.

Recommended Extensions:

* AWS Toolkit
* Docker
* Kubernetes
* YAML
* Terraform
* Extension Pack for Java
* GitHub Pull Requests and Issues

Status:

✅ Installed

---

# AWS CLI

Purpose:

Interact with AWS Services.

Verification:

```bash
aws --version
```

Current Status:

✅ Installed

Verify Credentials:

```bash
aws sts get-caller-identity
```

Current Result:

Account ID:

```text
761018849945
```

IAM User:

```text
Admin-User
```

Status:

✅ Working

---

# Terraform

Purpose:

Infrastructure as Code.

Verification:

```bash
terraform version
```

Status:

✅ Installed

Common Commands:

```bash
terraform init

terraform validate

terraform plan

terraform apply

terraform destroy
```

---

# kubectl

Purpose:

Manage Kubernetes clusters.

Verification:

```bash
kubectl version --client
```

Status:

✅ Installed

Common Commands:

```bash
kubectl get nodes

kubectl get pods -A

kubectl describe pod POD_NAME

kubectl logs POD_NAME
```

---

# Helm

Purpose:

Package Manager for Kubernetes.

Verification:

```bash
helm version
```

Status:

✅ Installed

Common Commands:

```bash
helm install

helm upgrade

helm list

helm uninstall
```

---

# Docker Desktop

Purpose:

Container Build and Runtime Environment.

Version:

```text
Docker 29.5.2
```

Verification:

```bash
docker --version
```

Result:

```text
Docker version 29.5.2
```

Status:

✅ Installed

---

# WSL2

Purpose:

Docker Backend and Linux Compatibility Layer.

Verification:

```powershell
wsl --status
```

Current Result:

```text
Default Distribution: docker-desktop

Default Version: 2
```

Status:

✅ Installed

---

# Docker Verification

Verify Docker Engine:

```bash
docker ps
```

Verify Docker Images:

```bash
docker images
```

Current Test Image:

```text
auth-service:v1
```

Status:

✅ Working

---

# Current Platform Tooling Status

Java                  ✅
Maven                 ✅
Git                   ✅
VS Code               ✅
AWS CLI               ✅
Terraform             ✅
Docker Desktop        ✅
WSL2                  ✅
kubectl               ✅
Helm                  ✅

---

# Platform Repositories

Infrastructure:

enterprise-platform-infra

Microservices:

enterprise-microservices

GitOps:

enterprise-platform-gitops

---

# Workstation Validation Checklist

Verify Java:

```bash
java -version
```

Verify Maven:

```bash
mvn -version
```

Verify AWS:

```bash
aws sts get-caller-identity
```

Verify Terraform:

```bash
terraform version
```

Verify Docker:

```bash
docker --version
```

Verify Kubernetes:

```bash
kubectl get nodes
```

Verify Helm:

```bash
helm version
```

---

# Purpose Of This Runbook

This document provides a complete workstation bootstrap guide.

If a new laptop is provisioned, following this document should recreate the full engineering environment.
