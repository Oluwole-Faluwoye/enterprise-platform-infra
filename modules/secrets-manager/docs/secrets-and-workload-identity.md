Secrets and Workload Identity

Secrets

Database credentials are managed through AWS Secrets Manager.

GitOps contains references/configuration, not static passwords.

Important troubleshooting distinction

A Secrets Manager object existing does not prove that a usable
AWSCURRENT version exists.

This distinction caused External Secrets synchronization failures during
live validation.

Workload identity

Auth-service uses:

enterprise-platform-dev-auth-service-database

through EKS workload identity/IRSA.

The application does not use static AWS access keys.

Runtime principle

Workload identity
      ↓
AWS authorization
      ↓
Secrets Manager
      ↓
Application