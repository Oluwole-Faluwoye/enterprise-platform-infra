# AWS Region Selection Strategy

## Overview

An AWS Region is a physical geographic location where AWS operates one or more data centers.

Examples:

* ca-central-1 (Canada Central – Montreal)
* us-east-1 (Northern Virginia)
* us-west-2 (Oregon)
* eu-west-1 (Ireland)

Every AWS resource is deployed into a specific region.

Examples:

* VPC
* EKS Cluster
* ECR Repository
* RDS Database
* EC2 Instances
* Load Balancers

---

# Why Region Selection Matters

Choosing a region affects:

* Latency
* Cost
* Compliance
* Disaster Recovery
* Service Availability

A poorly chosen region can increase application response times and operational complexity.

---

# Current Project Region

Selected Region:

```text
ca-central-1
```

Reason:

The project owner is located in Canada and the platform is intended to simulate a Canadian production environment.

---

# Latency Considerations

Users closer to an AWS Region experience lower latency.

Example:

```text
User in Canada
↓
ca-central-1
↓
Lower Latency
```

Compared to:

```text
User in Canada
↓
us-east-1
↓
Higher Latency
```

Approximate Comparison:

| Route                 | Approximate Latency |
| --------------------- | ------------------- |
| Canada → ca-central-1 | 15–40 ms            |
| Canada → us-east-1    | 40–80 ms            |

Actual values vary by ISP and location.

---

# Data Residency

Many organizations require customer data to remain within a specific country.

Examples:

* Government Agencies
* Healthcare Providers
* Financial Institutions

Using:

```text
ca-central-1
```

helps keep workloads and data within Canada.

---

# Why Many Tutorials Use us-east-1

The majority of AWS tutorials use:

```text
us-east-1
```

because:

* Largest AWS Region
* Most AWS services available
* New services often launch there first
* Largest AWS customer base
* Extensive community documentation

This makes it a popular learning region.

---

# Why This Project Uses ca-central-1

Benefits:

* Lower latency for Canadian users
* Better alignment with Canadian businesses
* Supports Canadian data residency requirements
* Consistent deployment strategy

All platform resources should use:

```text
ca-central-1
```

including:

* Terraform Infrastructure
* EKS Cluster
* ECR Repositories
* Load Balancers
* Monitoring Stack

---

# Region Consistency

A common mistake is deploying resources across multiple regions unintentionally.

Example:

```text
EKS Cluster      → ca-central-1
ECR Repository   → us-east-1
```

Result:

* Image pull failures
* Increased latency
* Additional complexity

Best Practice:

Deploy related resources within the same region unless a multi-region design is intentional.

---

# Current Project Architecture

Region:

```text
ca-central-1
```

Components:

```text
Terraform
↓
VPC
↓
Amazon EKS
↓
Amazon ECR
↓
Jenkins
↓
SonarQube
↓
ArgoCD
↓
Prometheus
↓
Grafana
↓
Loki
↓
OpenTelemetry
```

---

# Future Disaster Recovery Strategy

A future enhancement of this platform will include:

Primary Region:

```text
ca-central-1
```

Secondary Region:

```text
us-east-1
```

Purpose:

* Disaster Recovery
* Backup Storage
* Cross-Region Replication
* Failover Testing

Architecture:

```text
Primary Region
(ca-central-1)
        │
        ▼
Cross-Region Replication
        │
        ▼
Disaster Recovery Region
(us-east-1)
```

---

# Interview Questions

## What is an AWS Region?

An AWS Region is a geographic area containing multiple isolated Availability Zones where AWS services are deployed.

---

## Why was ca-central-1 selected for this project?

Because the platform is intended to simulate a Canadian production environment while providing lower latency and supporting Canadian data residency requirements.

---

## Why not use us-east-1?

Although us-east-1 offers broad service availability and is widely used, ca-central-1 provides better regional alignment for Canadian workloads.

---

## What is a multi-region architecture?

A multi-region architecture deploys resources across multiple AWS regions to improve availability, resiliency, and disaster recovery capabilities.

---

# Key Concepts Learned

* AWS Regions
* Availability Zones
* Latency Optimization
* Data Residency
* Regional Architecture
* Disaster Recovery
* Multi-Region Design
* Cross-Region Replication
