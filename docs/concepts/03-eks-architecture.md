# Amazon EKS Architecture

## Overview

Amazon Elastic Kubernetes Service (EKS) is AWS's managed Kubernetes platform.

EKS removes the operational burden of managing Kubernetes control plane components while allowing engineers to focus on deploying and operating workloads.

This project uses EKS as the orchestration layer for running containerized applications in a highly available and scalable environment.

---

# What Problem Does Kubernetes Solve?

Before Kubernetes:

```text
Application
↓
EC2 Instance
```

Problems:

* Manual deployments
* Poor scalability
* Difficult upgrades
* No self-healing
* Limited automation

As applications grow:

```text
Frontend
Backend
Database
Notifications
Payments
Authentication
```

Managing containers manually becomes difficult.

Kubernetes solves:

* Container orchestration
* Scheduling
* Self-healing
* Scaling
* Service discovery
* Rolling deployments

---

# What Problem Does EKS Solve?

Managing Kubernetes yourself requires operating:

* API Server
* Scheduler
* etcd
* Controller Manager

AWS manages these components through EKS.

Benefits:

* Reduced operational overhead
* High availability
* Security updates
* Automatic control plane management

---

# EKS Architecture

```text
AWS Account
│
├── VPC
│
├── Public Subnets
│   ├── ALB
│   └── NAT Gateway
│
├── Private Subnets
│   ├── Worker Nodes
│   └── Pods
│
└── EKS Cluster
    │
    ├── Control Plane
    └── Worker Nodes
```

---

# EKS Control Plane

The control plane is the brain of Kubernetes.

AWS manages:

* Kubernetes API Server
* Scheduler
* Controller Manager
* etcd

Engineers do not directly manage these components.

---

# Kubernetes API Server

The API Server is the front door of Kubernetes.

Every action passes through it.

Examples:

```bash
kubectl get pods

kubectl get nodes

kubectl apply -f deployment.yaml
```

All communicate with:

```text
Kubernetes API Server
```

---

# etcd

etcd is Kubernetes' database.

Stores:

* Pods
* Deployments
* Services
* Secrets
* ConfigMaps

Everything inside the cluster is stored in etcd.

---

# Scheduler

The Scheduler decides:

```text
Which node runs which pod?
```

When a new pod is created:

```text
Deployment
↓
Pod Created
↓
Scheduler Selects Node
↓
Pod Runs
```

---

# Controller Manager

Controllers constantly compare:

```text
Desired State
vs
Actual State
```

Example:

Desired:

```text
3 Pods
```

Actual:

```text
2 Pods
```

Controller detects the difference and creates a replacement pod.

This is self-healing.

---

# Worker Nodes

Worker Nodes run workloads.

Responsibilities:

* Running Pods
* Pulling container images
* Executing application code

Your applications never run on the control plane.

They run on worker nodes.

---

# Managed Node Groups

This project uses EKS Managed Node Groups.

Benefits:

* AWS manages lifecycle
* Easier upgrades
* Simpler scaling
* Better maintenance

Terraform defines:

```hcl
desired_size
min_size
max_size
```

---

# Node Group Scaling

Example:

```text
Desired: 2
Min: 2
Max: 5
```

Behavior:

Normal:

```text
2 Nodes
```

Under heavy load:

```text
5 Nodes
```

Cluster Autoscaler can automate this process.

---

# What Happens When A Pod Is Created?

Example:

```bash
kubectl apply -f deployment.yaml
```

Flow:

```text
Deployment Created
↓
API Server Receives Request
↓
ReplicaSet Created
↓
Pod Created
↓
Scheduler Assigns Node
↓
Kubelet Starts Container
↓
Application Running
```

---

# Kubelet

Kubelet runs on every worker node.

Responsibilities:

* Communicate with API Server
* Start containers
* Monitor containers
* Report node health

Without kubelet:

Pods cannot run.

---

# Container Runtime

Container runtime executes containers.

Examples:

* containerd
* CRI-O

EKS uses containerd.

Responsibilities:

* Pull images
* Start containers
* Stop containers

---

# Why Nodes Are In Private Subnets

Worker nodes should not be exposed directly to the internet.

Benefits:

* Better security
* Reduced attack surface
* Production best practice

Traffic enters through:

```text
ALB
↓
Ingress
↓
Service
↓
Pod
```

Not directly through worker nodes.

---

# kubectl Authentication

To connect to EKS:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name my-cluster
```

This updates:

```text
~/.kube/config
```

kubectl then authenticates through AWS IAM.

---

# Common kubectl Commands

Cluster

```bash
kubectl cluster-info

kubectl get nodes

kubectl describe node
```

Pods

```bash
kubectl get pods

kubectl get pods -A

kubectl describe pod POD_NAME

kubectl logs POD_NAME
```

Deployments

```bash
kubectl get deployments

kubectl describe deployment DEPLOYMENT_NAME
```

Services

```bash
kubectl get svc
```

Namespaces

```bash
kubectl get ns
```

Events

```bash
kubectl get events

kubectl get events --sort-by=.metadata.creationTimestamp
```

---

# Common Troubleshooting

Node Not Ready

Check:

```bash
kubectl get nodes

kubectl describe node NODE_NAME
```

---

Pod CrashLoopBackOff

Check:

```bash
kubectl logs POD_NAME

kubectl describe pod POD_NAME
```

---

ImagePullBackOff

Possible causes:

* Wrong image name
* Missing ECR permissions
* Authentication issues

---

Pending Pods

Possible causes:

* Insufficient CPU
* Insufficient memory
* Scheduling constraints

Check:

```bash
kubectl describe pod POD_NAME
```

---

# Interview Questions

Q: What is the Kubernetes Control Plane?

A:

The control plane manages cluster operations including scheduling, state management, and orchestration. In EKS, AWS manages the control plane.

---

Q: What is etcd?

A:

etcd is Kubernetes' distributed key-value store used to store cluster state.

---

Q: What is the role of the Scheduler?

A:

The Scheduler determines which worker node should run a pod based on resource availability and constraints.

---

Q: What is Kubelet?

A:

Kubelet runs on each worker node and communicates with the API Server to manage pod execution.

---

Q: Why are worker nodes placed in private subnets?

A:

To reduce attack surface and improve security by preventing direct internet access.

---

# Concepts Learned

* Amazon EKS
* Control Plane
* Worker Nodes
* API Server
* Scheduler
* Controller Manager
* etcd
* Kubelet
* Container Runtime
* Managed Node Groups
* Kubernetes Architecture
* Cluster Scaling
* EKS Security
* Kubernetes Operations
