# Kubernetes Fundamentals

## Overview

Kubernetes is a container orchestration platform responsible for deploying, scaling, networking, and managing containerized applications.

Understanding Kubernetes requires understanding its core objects.

Every Kubernetes application is built from these foundational building blocks.

---

# Kubernetes Object Hierarchy

A common mistake is thinking that applications run directly as Pods.

The actual hierarchy is:

```text
Deployment
    │
    ▼
ReplicaSet
    │
    ▼
Pods
    │
    ▼
Containers
```

Understanding this hierarchy is critical.

---

# What Is A Pod?

A Pod is the smallest deployable unit in Kubernetes.

A Pod contains:

* One or more containers
* Shared networking
* Shared storage

Example:

```text
Pod
│
├── Java Application Container
└── Sidecar Container
```

Most applications use:

```text
1 Pod
1 Container
```

Initially.

---

# Why Pods Exist

Containers themselves are not managed directly by Kubernetes.

Kubernetes manages Pods.

Pods provide:

* Scheduling
* Networking
* Lifecycle management

Think of Pods as wrappers around containers.

---

# Pod Lifecycle

```text
Pending
↓
Running
↓
Succeeded
```

Possible failure states:

```text
CrashLoopBackOff
ImagePullBackOff
Error
Unknown
```

---

# Viewing Pods

```bash
kubectl get pods

kubectl get pods -A

kubectl describe pod POD_NAME

kubectl logs POD_NAME
```

---

# Why You Rarely Create Pods Directly

Example:

```yaml
apiVersion: v1
kind: Pod
```

Problem:

If the Pod dies:

```text
Pod
↓
Deleted
↓
Application Gone
```

Kubernetes does not recreate it automatically.

Production systems require self-healing.

---

# ReplicaSets

ReplicaSets maintain a desired number of Pods.

Example:

Desired:

```text
3 Pods
```

Actual:

```text
2 Pods
```

ReplicaSet detects the difference and creates a replacement.

---

# ReplicaSet Example

```text
ReplicaSet
│
├── Pod A
├── Pod B
└── Pod C
```

If Pod B fails:

```text
ReplicaSet
↓
Creates New Pod
```

Desired state is restored.

---

# Deployments

Deployments manage ReplicaSets.

This is the preferred way to deploy applications.

Hierarchy:

```text
Deployment
↓
ReplicaSet
↓
Pods
```

Deployments provide:

* Rolling updates
* Rollbacks
* Self-healing
* Version control

---

# Deployment Example

Desired:

```text
3 Replicas
```

Deployment creates:

```text
ReplicaSet
↓
3 Pods
```

---

# Common Deployment Commands

```bash
kubectl get deployments

kubectl describe deployment APP

kubectl rollout status deployment APP

kubectl rollout history deployment APP

kubectl rollout undo deployment APP
```

---

# Services

Pods are temporary.

Pod IP addresses change.

Therefore applications cannot communicate directly with Pod IPs.

Kubernetes introduces Services.

---

# Why Services Exist

Without Services:

```text
Frontend
↓
Pod IP
```

Pod restarts:

```text
New Pod
New IP
Application Breaks
```

With Services:

```text
Frontend
↓
Service
↓
Pods
```

The Service remains stable.

Pods can change.

---

# Service Types

## ClusterIP

Default.

Internal communication only.

Example:

```text
Frontend
↓
Backend Service
```

---

## NodePort

Exposes application through worker nodes.

Example:

```text
NODE_IP:30000
```

Useful for learning.

Less common in production.

---

## LoadBalancer

Creates cloud load balancer.

Example:

```text
AWS ELB
↓
Application
```

Very common in cloud environments.

---

# Ingress

Ingress manages HTTP and HTTPS routing.

Without Ingress:

```text
Load Balancer
Per Service
```

Expensive and inefficient.

With Ingress:

```text
ALB
↓
Ingress
↓
Multiple Services
```

---

# Example Traffic Flow

```text
Browser
↓
ALB
↓
Ingress
↓
Service
↓
Pod
```

This is how your project works today.

---

# Namespaces

Namespaces logically separate workloads.

Think of them as folders inside Kubernetes.

Example:

```text
default
argocd
monitoring
jenkins
dev
staging
prod
```

Benefits:

* Isolation
* Resource separation
* Security boundaries

---

# Namespace Commands

```bash
kubectl get ns

kubectl create ns dev

kubectl create ns staging

kubectl create ns prod
```

---

# ConfigMaps

ConfigMaps store non-sensitive configuration.

Examples:

* URLs
* Feature flags
* Environment variables

Bad:

```yaml
DATABASE_URL=inside-code
```

Good:

```yaml
ConfigMap
```

Applications consume configuration externally.

---

# Secrets

Secrets store sensitive information.

Examples:

* Passwords
* API keys
* Tokens

Examples:

```text
Database Password
JWT Secret
AWS Credentials
```

Secrets should never be hardcoded.

---

# Persistent Volumes

Pods are ephemeral.

Data inside a Pod disappears when the Pod dies.

Persistent Volumes solve this problem.

Examples:

* Databases
* Jenkins
* SonarQube

Storage survives Pod restarts.

---

# Resource Requests

Requests reserve resources.

Example:

```yaml
requests:
  cpu: 250m
  memory: 256Mi
```

Scheduler uses requests to place Pods.

---

# Resource Limits

Limits prevent resource abuse.

Example:

```yaml
limits:
  cpu: 500m
  memory: 512Mi
```

Without limits:

One application can consume all cluster resources.

---

# Liveness Probe

Question:

```text
Is the application alive?
```

If unhealthy:

```text
Restart Pod
```

---

# Readiness Probe

Question:

```text
Can this application receive traffic?
```

If unhealthy:

```text
Remove From Service
```

Traffic stops flowing to that Pod.

---

# Interview Questions

Q: Why don't we deploy Pods directly?

A:

Pods are not self-healing. Deployments and ReplicaSets provide resiliency, scaling, and lifecycle management.

---

Q: Why do Services exist?

A:

Pods are ephemeral and receive dynamic IP addresses. Services provide stable networking endpoints.

---

Q: Difference between ConfigMap and Secret?

A:

ConfigMaps store non-sensitive configuration. Secrets store sensitive information such as passwords and tokens.

---

Q: What is the purpose of a Deployment?

A:

Deployments manage ReplicaSets and provide rolling updates, rollbacks, scaling, and self-healing.

---

# Concepts Learned

* Pods
* ReplicaSets
* Deployments
* Services
* Ingress
* Namespaces
* ConfigMaps
* Secrets
* Persistent Volumes
* Resource Requests
* Resource Limits
* Liveness Probes
* Readiness Probes
* Kubernetes Networking
