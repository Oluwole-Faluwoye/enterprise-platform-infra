DEV Environment

Current network

VPC: 10.10.0.0/16

Public:
10.10.1.0/24
10.10.2.0/24

Private:
10.10.11.0/24
10.10.12.0/24

Database:
10.10.21.0/24
10.10.22.0/24

Runtime

EKS: enterprise-platform-dev
Region: us-east-1

Lifecycle controls

enable_eks         = true
enable_nat_gateway = true

for an active testing window.

For controlled shutdown:

enable_eks         = false
enable_nat_gateway = false

Composition-layer DNS rules

environments/dev/main.tf owns application-SG-to-node-SG DNS ingress
because both sides are available there.

Rules:

application SG → node SG TCP/53
application SG → node SG UDP/53

This supports CoreDNS access for pods using Security Groups for Pods.