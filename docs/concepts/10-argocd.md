# ArgoCD

## Overview

ArgoCD is a GitOps continuous delivery platform for Kubernetes.

It continuously monitors Git repositories and ensures that the Kubernetes cluster matches the desired state stored in Git.

---

# What Problem ArgoCD Solves

Traditional Deployment Flow

Developer
↓
Jenkins
↓
kubectl apply
↓
Cluster

Problems:

* Manual deployments
* Configuration drift
* Limited auditability

---

# GitOps Deployment Flow

Developer
↓
Git Commit
↓
Git Repository
↓
ArgoCD
↓
Kubernetes Cluster

Git becomes the source of truth.

---

# Desired State vs Actual State

Desired State:

Stored in Git

Actual State:

Running in Kubernetes

ArgoCD continuously compares both states.

---

# Drift Detection

Example:

Someone manually changes a Deployment:

```bash
kubectl edit deployment auth-service
```

ArgoCD detects the difference.

Possible Actions:

* Alert
* Auto-heal
* Re-sync

---

# Benefits

* Declarative deployments
* Rollback capability
* Drift detection
* Improved auditability
* Git-based change management

---

# Common Commands

Install CLI:

```bash
argocd version
```

Login:

```bash
argocd login
```

List Applications:

```bash
argocd app list
```

Sync Application:

```bash
argocd app sync auth-service
```

---

# Interview Questions

Q: What is GitOps?

A:

GitOps is an operational model where Git repositories serve as the source of truth for infrastructure and application deployment.

Q: What problem does ArgoCD solve?

A:

ArgoCD automates Kubernetes deployments and prevents configuration drift through Git synchronization.

---

# Concepts Learned

* GitOps
* Desired State
* Drift Detection
* Continuous Delivery
* Kubernetes Automation
