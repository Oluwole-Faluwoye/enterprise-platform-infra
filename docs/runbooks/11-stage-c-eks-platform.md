# Stage C - EKS Platform

## Objective

Allow Jenkins to deploy Kubernetes platform.

Prerequisite:

Stage B Complete

---

# Create Infrastructure Pipeline

Repository:

enterprise-platform-infra

Jenkinsfile

terraform fmt

terraform validate

terraform plan

terraform apply

---

# Enable EKS

terraform.tfvars

enable_eks = true

---

# Commit Changes

git add .

git commit -m "Enable EKS"

git push

---

# Jenkins Pipeline

GitHub

↓

Jenkins

↓

Terraform

↓

EKS

---

# Verify

aws eks list-clusters

kubectl get nodes

---

# Expected Outcome

EKS platform deployed through Jenkins.
