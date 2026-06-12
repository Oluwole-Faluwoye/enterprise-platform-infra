# AWS Networking Foundation

## Overview

Networking is the foundation of every cloud-native platform.

Before Kubernetes, EKS, Jenkins, ArgoCD, Prometheus, or microservices can function correctly, the underlying network architecture must be designed properly.

This document explains the networking architecture used in this project and the reasoning behind each component.

---

# High-Level Architecture

```text
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnets
    │
    ├── Application Load Balancer (ALB)
    └── NAT Gateway
    │
    ▼
Private Subnets
    │
    ├── EKS Worker Nodes
    ├── Kubernetes Pods
    └── Internal Services
```

---

# What Is A VPC?

A Virtual Private Cloud (VPC) is a logically isolated network inside AWS.

Think of it as your own private data center within AWS.

Example:

```text
10.0.0.0/16
```

The CIDR block determines the IP address range available inside the VPC.

---

# CIDR Blocks

CIDR (Classless Inter-Domain Routing) defines the available IP address space.

Example:

```text
10.0.0.0/16
```

This provides:

```text
65,536 IP addresses
```

Subnets divide this space into smaller ranges.

Example:

```text
10.0.1.0/24
10.0.2.0/24
10.0.3.0/24
10.0.4.0/24
```

Each /24 subnet contains:

```text
256 IP addresses
```

---

# Availability Zones (AZs)

AWS regions contain multiple Availability Zones.

Example:

```text
us-east-1a
us-east-1b
us-east-1c
```

Production systems should span multiple AZs.

Benefits:

* High availability
* Fault tolerance
* Reduced downtime

If one AZ fails, workloads continue running in another AZ.

---

# Public Subnets

Public subnets contain resources that require internet access.

Examples:

* Application Load Balancers
* NAT Gateways
* Bastion Hosts

A subnet becomes public when its route table contains:

```text
0.0.0.0/0 → Internet Gateway
```

This route allows internet traffic to enter and leave the subnet.

---

# Private Subnets

Private subnets do not allow direct inbound internet access.

Examples:

* EKS Worker Nodes
* Kubernetes Pods
* Databases
* Internal Services

Production workloads should reside in private subnets whenever possible.

Benefits:

* Smaller attack surface
* Improved security
* Better compliance posture

---

# Internet Gateway (IGW)

The Internet Gateway provides connectivity between the VPC and the public internet.

Architecture:

```text
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnet
```

Without an Internet Gateway:

* No inbound internet traffic
* No outbound internet traffic

Public resources require an IGW.

---

# NAT Gateway

A NAT Gateway allows resources in private subnets to access the internet without exposing them to inbound internet traffic.

Example:

```text
Private EKS Node
        │
        ▼
   NAT Gateway
        │
        ▼
     Internet
```

Common use cases:

* Pulling Docker images
* Accessing AWS APIs
* Downloading software updates

The internet cannot directly initiate communication back to the private node.

---

# Why NAT Gateways Must Be In Public Subnets

NAT Gateways require access to the internet.

Therefore they must reside in a subnet that has:

```text
0.0.0.0/0 → Internet Gateway
```

A NAT Gateway placed in a private subnet cannot function correctly.

---

# Route Tables

Route tables determine where traffic should go.

Think of them as traffic maps.

Example:

Public Route Table

```text
Destination     Target
0.0.0.0/0       Internet Gateway
```

Private Route Table

```text
Destination     Target
0.0.0.0/0       NAT Gateway
```

---

# Security Groups

Security Groups act as virtual firewalls.

They control:

* Inbound traffic
* Outbound traffic

Example:

Allow:

```text
HTTPS (443)
HTTP (80)
SSH (22)
```

Security Groups are stateful.

This means return traffic is automatically allowed.

---

# Network ACLs

Network ACLs operate at the subnet level.

Unlike Security Groups:

* Stateless
* Evaluated in order
* Can explicitly deny traffic

In most environments:

Security Groups provide the primary access control.

---

# Why EKS Worker Nodes Use Private Subnets

Worker nodes host application workloads.

Exposing worker nodes directly to the internet increases risk.

Benefits of private nodes:

* Reduced attack surface
* Improved security
* Better isolation

Production Kubernetes clusters typically keep worker nodes private.

---

# Packet Flow Through The Platform

When a user accesses the application:

```text
Browser
    │
    ▼
DNS (Route53)
    │
    ▼
Application Load Balancer
    │
    ▼
Ingress Controller
    │
    ▼
Kubernetes Service
    │
    ▼
Pod
    │
    ▼
Container
```

Understanding this flow is critical for troubleshooting.

---

# Common Networking Troubleshooting Commands

AWS

```bash
aws ec2 describe-vpcs

aws ec2 describe-subnets

aws ec2 describe-route-tables

aws ec2 describe-security-groups
```

Kubernetes

```bash
kubectl get svc

kubectl get ingress

kubectl get endpoints

kubectl get pods -o wide

kubectl describe ingress
```

Node Connectivity

```bash
curl

ping

nslookup

dig
```

---

# Common Failure Scenarios

Scenario 1

Pods cannot pull images.

Possible Causes:

* NAT Gateway failure
* Route table misconfiguration
* Security Group restrictions

---

Scenario 2

Application unreachable from internet.

Possible Causes:

* ALB misconfiguration
* Ingress issues
* DNS issues
* Security Group rules

---

Scenario 3

Pods cannot communicate internally.

Possible Causes:

* Service misconfiguration
* Network Policies
* DNS failures

---

# Interview Questions

Q: Why do EKS worker nodes typically run in private subnets?

A:

Private subnets reduce exposure to the public internet and improve security by limiting inbound access to worker nodes.

---

Q: What is the purpose of a NAT Gateway?

A:

A NAT Gateway allows private resources to access the internet while preventing inbound internet-initiated connections.

---

Q: Why are multiple Availability Zones used?

A:

Multiple AZs provide high availability and fault tolerance. If one AZ fails, workloads continue operating in another AZ.

---

Q: What is the difference between a Security Group and a Network ACL?

A:

Security Groups are stateful and operate at the resource level. Network ACLs are stateless and operate at the subnet level.

---

# Concepts Learned

* VPC
* CIDR Blocks
* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables
* Security Groups
* Network ACLs
* High Availability
* Packet Flow
* AWS Networking Architecture
* EKS Network Design
