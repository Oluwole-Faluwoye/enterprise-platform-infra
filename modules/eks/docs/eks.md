EKS

Cluster

enterprise-platform-dev

API

Both public and private endpoint access are enabled.

Public access is restricted by an allow-list:

cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = var.allowed_k8s_api_cidrs

Addon ordering

VPC CNI is deliberately provisioned before compute.

Access troubleshooting

aws sts get-caller-identity
aws eks update-kubeconfig --region us-east-1 --name enterprise-platform-dev
kubectl get nodes

Architecture decision

The EKS module does not receive application SG IDs.

Application-specific DNS ingress is composed in the environment layer to
avoid backwards dependency from foundational EKS to application
provisioning.