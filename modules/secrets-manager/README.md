# AWS Secrets Manager Terraform Module

# Overview

The Secrets Manager module provisions AWS Secrets Manager secrets for the Enterprise Platform.

Rather than creating individual secrets throughout the Terraform codebase, this module provides a reusable and scalable mechanism for provisioning secrets consistently across multiple environments.

The module is intentionally generic. It does not know anything about Grafana, PostgreSQL, JWT tokens, or SMTP credentials. Instead, it creates any secrets supplied by the calling environment using a single implementation.

This design follows Infrastructure as Code (IaC) best practices by separating infrastructure implementation from environment-specific configuration.

---

# Objectives

The module has been designed to achieve the following goals:

- Provision AWS Secrets Manager secrets consistently.
- Eliminate duplicated Terraform code.
- Support multiple deployment environments.
- Standardize secret naming.
- Apply consistent tagging.
- Enable future integration with External Secrets Operator.
- Support GitOps without storing secrets in Git.

---

# Module Responsibilities

The module is responsible for:

- Creating AWS Secrets Manager secret containers.
- Applying enterprise tagging.
- Enforcing a consistent naming convention.
- Returning Secret ARNs for downstream infrastructure.

The module intentionally does **not**:

- Create secret values.
- Store passwords.
- Rotate secrets.
- Manage Kubernetes Secrets.

Those responsibilities belong to operational workflows and the Kubernetes platform.

---

# Naming Convention

Secrets follow the naming convention:

```
<project>/<environment>/<secret-name>
```

Example:

```
enterprise-platform/dev/grafana/admin

enterprise-platform/dev/auth-service

enterprise-platform/dev/alertmanager

enterprise-platform/dev/postgres
```

This convention provides:

- Logical organization
- Multi-environment support
- Predictable naming
- Easier discovery
- No naming collisions

---

# Inputs

| Variable | Description |
|----------|-------------|
| `project` | Project name |
| `environment` | Deployment environment |
| `secrets` | Map of secrets to provision |

Example:

```hcl
secrets = {

  "grafana/admin" = {
    description = "Grafana Administrator"
  }

  "auth-service" = {
    description = "Auth Service"
  }

}
```

---

# Outputs

The module returns a map containing every created Secret ARN.

Example:

```hcl
secret_arns = {

  "grafana/admin" = "...ARN..."

  "auth-service" = "...ARN..."

}
```

These outputs can be consumed by:

- IAM Policies
- External Secrets
- Terraform Modules
- Platform Automation

---

# Why Use `for_each`?

Earlier implementations required creating one Terraform resource for every secret.

Example:

```hcl
resource "aws_secretsmanager_secret" "grafana" {}

resource "aws_secretsmanager_secret" "smtp" {}

resource "aws_secretsmanager_secret" "postgres" {}
```

This approach does not scale.

Instead, the module uses:

```hcl
for_each
```

Benefits include:

- One implementation
- Unlimited secrets
- Reduced code duplication
- Easier maintenance
- Simpler onboarding
- Better scalability

Adding a new secret requires only updating the input map.

No module modifications are necessary.

---

# Tagging Strategy

Every secret receives the same standard tags.

```
Project

Environment

Terraform
```

Consistent tagging enables:

- Cost allocation
- Resource discovery
- Governance
- Automation
- Operational reporting

Future tags such as:

```
Owner

BusinessUnit

CostCenter

Compliance
```

can be added centrally without modifying individual resources.

---

# Example Usage

```hcl
module "secrets_manager" {

  source = "../../modules/secrets-manager"

  project = var.project_name

  environment = var.environment

  secrets = {

    "grafana/admin" = {

      description = "Grafana Administrator"

    }

    "alertmanager" = {

      description = "Alertmanager SMTP"

    }

  }

}
```

---

# Future Integration with External Secrets Operator

This module provisions only the AWS Secrets Manager resources.

The secrets will later be consumed by the Kubernetes platform through:

```
Terraform

↓

AWS Secrets Manager

↓

External Secrets Operator

↓

ClusterSecretStore

↓

ExternalSecret

↓

Kubernetes Secret

↓

Application
```

Applications will never communicate directly with AWS Secrets Manager.

Instead, Kubernetes Secrets will be synchronized automatically by the External Secrets Operator.

This architecture removes sensitive credentials from Git while maintaining compatibility with GitOps and Infrastructure as Code.

---

# Summary

The Secrets Manager module provides a reusable, scalable, and environment-agnostic approach to provisioning AWS Secrets Manager resources.

By using a generic implementation based on `for_each`, the module supports future platform growth while minimizing Terraform code duplication.

It establishes the foundation for enterprise secrets management, enabling secure integration with Kubernetes through the External Secrets Operator and ensuring that future platform services can consume secrets without exposing credentials in source control.