# AWS Secrets Manager

## Overview

This platform uses **AWS Secrets Manager** together with the **External Secrets Operator (ESO)** to securely provide application secrets to workloads running on Amazon EKS.

Terraform is responsible for creating the **Secrets Manager secret containers** only.

The actual secret values are populated separately. This design intentionally separates infrastructure provisioning from secret management and aligns with enterprise Infrastructure as Code (IaC) best practices.

---

# Architecture

```
Terraform
      │
      ▼
AWS Secrets Manager
(Secret Containers)

      │
      ▼
Bootstrap Script (Development)
or
Enterprise Secret Management Process (Production)

      │
      ▼
Secrets Manager Secret Values

      │
      ▼
External Secrets Operator

      │
      ▼
Kubernetes Secrets

      │
      ▼
Applications
```

---

# Why This Approach?

Terraform provisions infrastructure.

Secret values are operational data and should not be stored inside Terraform configuration or Terraform state.

Separating these responsibilities provides several benefits:

- Infrastructure can be recreated safely.
- Secret values remain independent of infrastructure code.
- Secret rotation becomes easier.
- Production environments can integrate with enterprise secret management processes.
- Sensitive credentials are never committed to Git.

---

# Secrets Created

Terraform creates the following AWS Secrets Manager secrets.

| Secret | Purpose |
|---------|----------|
| enterprise-platform/dev/auth-service | Authentication Service configuration |
| enterprise-platform/dev/grafana/admin | Grafana administrator credentials |
| enterprise-platform/dev/alertmanager | Alertmanager SMTP configuration |

Initially, these secrets contain **no values**.

---

# Deploy Infrastructure

Deploy the infrastructure normally.

```bash
terraform init

terraform plan

terraform apply
```

Verify that the secret containers were created.

```bash
aws secretsmanager list-secrets
```

Expected output includes:

```
enterprise-platform/dev/auth-service

enterprise-platform/dev/grafana/admin

enterprise-platform/dev/alertmanager
```

---

# Bootstrap Development Secrets

For development environments, populate the secrets using the bootstrap script.

Navigate to the development environment.

-----------------------------------------------------------

If you have created the secret operators before and you deleted them, they usually do not delete automatically, they are often scheduled for deletion and this affects your pipeline, i.e your pipeline would fail at that point, what you have to do is restore the secrets from deletion and then copy the state of the secrets into the state file before running the bootstrap-secrets.sh .. the commands are as follows : 

----------------------------------------------------------------------------
This restores the secrets
-----------------------------------------------------------------------------

aws secretsmanager restore-secret \
  --secret-id enterprise-platform/dev/auth-service

aws secretsmanager restore-secret \
  --secret-id enterprise-platform/dev/grafana/admin

aws secretsmanager restore-secret \
  --secret-id enterprise-platform/dev/alertmanager

-------------------------------------------------------------------------
verify they are back 
-------------------------------------------------------------

aws secretsmanager describe-secret \
  --secret-id enterprise-platform/dev/auth-service

aws secretsmanager describe-secret \
  --secret-id enterprise-platform/dev/grafana/admin

aws secretsmanager describe-secret \
  --secret-id enterprise-platform/dev/alertmanager


-----------------------------------------------------------------------------------------
This imports them into the statefile
-----------------------------------------------------------------

terraform import \
'module.secrets_manager.aws_secretsmanager_secret.this["auth-service"]' \
enterprise-platform/dev/auth-service

terraform import \
'module.secrets_manager.aws_secretsmanager_secret.this["grafana/admin"]' \
enterprise-platform/dev/grafana/admin

terraform import \
'module.secrets_manager.aws_secretsmanager_secret.this["alertmanager"]' \
enterprise-platform/dev/alertmanager
------------------------------------------------------------------------
Verify Imports
----------------------------------------------------------

terraform state list | grep secretsmanager


-------------------------------------------------------------------
You should see something similar to this : 
---------------------------------------------

module.secrets_manager.aws_secretsmanager_secret.this["auth-service"]
module.secrets_manager.aws_secretsmanager_secret.this["grafana/admin"]
module.secrets_manager.aws_secretsmanager_secret.this["alertmanager"]




cd environments/dev


Run:

./bootstrap-secrets.sh


The script inserts the initial secret values into AWS Secrets Manager.

---

# Verify Secret Values

Verify that a secret now contains an active version.


aws secretsmanager get-secret-value \
  --secret-id enterprise-platform/dev/auth-service


The command should return the JSON stored in the secret.

-------------------------------------
Update your kubeconfig
-----------------------------------

aws eks update-kubeconfig \
  --region us-east-1 \
  --name devops-cluster

# External Secrets Synchronization

After the secret values exist, External Secrets Operator automatically synchronizes them into Kubernetes.

Verify synchronization.

```bash
kubectl get externalsecret -A
```

Expected:

```
READY   STATUS

True    SecretSynced
```

---

# Verify Kubernetes Secrets

Confirm that Kubernetes Secrets were created.

```bash
kubectl get secrets -A
```

Example:

```
auth-service-secret

grafana-secret

alertmanager-secret
```

---

# Verify Applications

Confirm the applications have started successfully.

```bash
kubectl get pods -A
```

Expected:

```
Running
```

for all platform services.

---

# Updating Secret Values

If a secret value changes, update it in AWS Secrets Manager.

Example:

```bash
aws secretsmanager put-secret-value \
  --secret-id enterprise-platform/dev/auth-service \
  --secret-string '{ ... }'
```

External Secrets Operator will automatically synchronize the updated values into Kubernetes.

---

# Production Deployment

The bootstrap script is intended **only for development and demonstration environments**.

For production environments, secret values should be managed using an approved enterprise process such as:

- AWS Secrets Manager Console
- AWS CLI executed by authorized administrators
- CI/CD pipeline
- Enterprise secret management platform (for example, HashiCorp Vault)
- Automated credential rotation

Terraform should create only the secret containers.

This separation ensures that infrastructure provisioning remains independent of sensitive application credentials.

---

# Troubleshooting

## Secret exists but ExternalSecret shows `SecretSyncedError`

Verify that the secret contains an active version.

```bash
aws secretsmanager list-secret-version-ids \
  --secret-id enterprise-platform/dev/auth-service
```

Expected:

```
Versions:
- AWSCURRENT
```

If no versions are present, execute the bootstrap script.

---

## ClusterSecretStore is not Ready

Verify the IAM Role for Service Accounts (IRSA) configuration.

```bash
kubectl describe clustersecretstore aws-secretsmanager
```

---

## Kubernetes Secret was not created

Check the External Secret.

```bash
kubectl describe externalsecret auth-service-secret -n auth
```

Review the Events section for synchronization errors.

---

# Summary

The deployment flow is:

1. Terraform creates AWS Secrets Manager secret containers.
2. Secret values are populated.
3. External Secrets Operator synchronizes the values.
4. Kubernetes Secrets are created.
5. Applications start successfully.

This design follows enterprise best practices by separating infrastructure provisioning from secret management.