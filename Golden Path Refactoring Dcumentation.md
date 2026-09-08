Enterprise Platform Infrastructure
Platform Architecture, Refactoring & Provisioning Design

Project: Enterprise Platform Infrastructure
Repository: enterprise-platform-infra
Primary Cloud: AWS
Primary Region: us-east-1
Architecture Status: Refactored Foundation / Golden Path Implementation
Last Updated: September 2026

1. Purpose

This document describes the architecture, design decisions, refactoring work, implementation patterns, testing approach, mistakes encountered, and fixes made while building the Enterprise Platform Infrastructure.

The goal is to create a reusable internal platform capable of allowing application teams to express what they need without requiring them to understand or directly manage the underlying AWS infrastructure.

The platform is being designed around the following principles:

Developers declare intent rather than infrastructure.
Environment infrastructure is owned by the environment.
Platform logic interprets developer intent.
Golden Paths implement approved infrastructure patterns.
Environment-specific context is supplied to the platform rather than hard-coded into developer requests.
Security and access decisions are separated from infrastructure creation.
Infrastructure should be reusable across DEV, STAGING, and PROD.
The platform should support progressive automation without requiring a redesign later.
2. Repository Structure

The current repository structure is:

enterprise-platform-infra/
│
├── environments/
│   ├── bootstrap/
│   ├── dev/
│   ├── staging/
│   └── prod/
│
├── modules/
│   ├── acm/
│   ├── application-security-group/
│   ├── database/
│   ├── ecr/
│   ├── eks/
│   ├── iam-bootstrap/
│   ├── iam-irsa/
│   ├── jenkins/
│   ├── networking/
│   ├── route53/
│   └── secrets-manager/
│
├── platform/
│   ├── resolver/
│   └── provisioning/
│
└── docs/
    └── architecture/

The architecture intentionally separates:

Environment
Module
Resolver
Provisioner

rather than placing all infrastructure decisions inside environment Terraform.

3. Target Architecture

The target architecture is:

                         DEVELOPER
                             │
                             │
                       Developer Intent
                             │
                             ▼
                       ┌───────────┐
                       │  Backstage │
                       │ (Control   │
                       │   Plane)   │
                       └─────┬─────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     RESOLVER    │
                    │                 │
                    │ Interpret intent│
                    │ Apply platform  │
                    │ rules           │
                    └────────┬────────┘
                             │
                     Resolved Actions
                             │
                             ▼
                    ┌─────────────────┐
                    │   PROVISIONER   │
                    │                 │
                    │ Execute actions │
                    │ using environment│
                    │ context         │
                    └────────┬────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
             Golden       Golden       Golden
              Path         Path         Path
              VPC          EKS        Database
                │            │            │
                └────────────┼────────────┘
                             │
                             ▼
                       AWS Resources

The important architectural boundary is:

Resolver decides what should happen. Provisioner makes it happen.

4. Environment Architecture

The platform separates the shared Bootstrap foundation from individual application environments.

                        AWS ACCOUNT
                            │
             ┌──────────────┴──────────────┐
             │                             │
             ▼                             ▼
        BOOTSTRAP                      ENVIRONMENTS
             │                             │
      ┌──────┼──────┐             ┌───────┼────────┐
      │      │      │             │       │        │
     VPC   Jenkins ECR           DEV   STAGING    PROD
      │                             │
      │                             ├── VPC
      │                             ├── NAT
      │                             ├── EKS
      │                             ├── ArgoCD
      │                             └── workloads
      │
      └── Shared platform foundation
Bootstrap

Bootstrap exists to provide infrastructure that supports the platform itself.

Current responsibilities include:

Bootstrap VPC
Jenkins
ECR where appropriate
Bootstrap IAM
Terraform deployment IAM
Terraform state infrastructure
Other shared foundation components

Bootstrap should survive the destruction of an individual environment.

5. Bootstrap VPC

Current Bootstrap configuration:

vpc_cidr = "10.0.0.0/16"

azs = [
  "us-east-1a",
  "us-east-1b"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.3.0/24",
  "10.0.4.0/24"
]

Jenkins is located in the public subnet.

NAT is currently disabled:

enable_nat_gateway = false

This is intentional.

Jenkins does not require NAT because it is deployed in a public subnet and can use its public connectivity.

6. Environment VPCs

Each environment owns its own VPC.

DEV currently uses:

VPC:
10.10.0.0/16

Public:
10.10.1.0/24
10.10.2.0/24

Private:
10.10.11.0/24
10.10.12.0/24

Database:
10.10.21.0/24
10.10.22.0/24

The environment owns:

VPC
Public subnets
Private subnets
Database subnets
NAT gateways
EKS
Environment-specific networking

This prevents Bootstrap from becoming a dependency for the lifecycle of application environments.

7. NAT Gateway Decision

One important architectural decision was made around NAT.

NAT is environment infrastructure, not developer intent.

Therefore the developer should never have to request:

enable_nat_gateway = true

The environment decides whether it requires NAT.

For example:

DEV
  NAT = enabled

STAGING
  NAT = enabled

PROD
  NAT = enabled

Cost-control behavior is also supported.

An environment can be stopped by setting:

enable_eks = false
enable_nat_gateway = false

while retaining the VPC and subnet infrastructure.

This allows expensive resources such as:

EKS
NAT gateways

to be removed independently of the underlying environment network.

8. Kubernetes Subnet Tagging

A previous implementation risk was having Kubernetes-specific subnet tags embedded into generic networking.

The networking module was generalized.

The module now accepts:

variable "enable_kubernetes_tags" {
  type    = bool
  default = false
}

and:

variable "cluster_name" {
  type    = string
  default = null
}

When enabled:

Public subnets receive:

kubernetes.io/role/elb = 1
kubernetes.io/cluster/<cluster-name> = shared

Private subnets receive:

kubernetes.io/role/internal-elb = 1
kubernetes.io/cluster/<cluster-name> = shared

Bootstrap does not enable these tags.

DEV does.

This keeps the networking module reusable for non-Kubernetes infrastructure.

9. EKS Architecture

DEV owns its EKS cluster.

Current cluster:

enterprise-platform-dev

EKS uses private subnets for worker nodes.

Current node group configuration:

Node group:
devops-nodes

Instance:
t3.medium

Desired:
3

Minimum:
2

Maximum:
3

Capacity:
ON_DEMAND

The EKS API endpoint is configured for both public and private access.

cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true

Public API access is restricted to explicitly allowed CIDRs.

10. EKS Connectivity Decision

A VPC peering approach between Bootstrap and DEV was considered.

It was ultimately rejected.

The reason is that the EKS cluster already supports:

Public API endpoint
+
Private API endpoint

and Jenkins can access the EKS public API endpoint when its public IP is allowed.

Therefore:

Bootstrap VPC
       │
       │ HTTPS 443
       │
       ▼
EKS public API endpoint
       │
       ▼
DEV EKS

does not require VPC peering.

The modules/vpc-peering module was therefore removed.

This simplified the architecture and eliminated unnecessary network coupling.

11. EKS Access Model

EKS access uses AWS EKS access entries.

The cluster grants administrative access to:

Jenkins deployment role
Terraform deployment role

through:

AmazonEKSClusterAdminPolicy

The EKS module deliberately disables:

enable_cluster_creator_admin_permissions = false

This avoids relying on the identity that happened to create the cluster.

Access is explicitly declared through the platform.

12. Bootstrap → Environment Dependency

The environment can consume selected Bootstrap outputs through Terraform remote state.

For example, DEV consumes:

Jenkins IAM role ARN
Terraform deployment role ARN

from Bootstrap.

This creates a controlled dependency:

Bootstrap
   │
   ├── Jenkins IAM role
   └── Terraform deployment role
           │
           ▼
          DEV

However, the platform Provisioner itself should not depend on Bootstrap remote state.

This distinction became important during the refactor.

13. Major Architecture Refactor

The previous architecture allowed the provisioning layer to depend directly on Bootstrap state.

This created unnecessary coupling.

The Provisioner was effectively expected to know things such as:

Bootstrap
VPC
Jenkins
subnets

This was not appropriate.

The Provisioner should not care how an environment was created.

It should only receive the infrastructure context it needs.

The architecture was therefore changed to:

Environment
     │
     │ environment_context
     ▼
Provisioner

instead of:

Provisioner
     │
     ▼
Bootstrap remote state
     │
     ▼
Environment infrastructure
14. Environment Context

The environment exposes a controlled interface:

output "environment_context" {
  value = {
    vpc_id              = module.networking.vpc_id
    private_subnet_ids  = module.networking.private_subnets
    database_subnet_ids = module.networking.database_subnets
    cluster_name        = var.cluster_name
  }
}

This creates an abstraction boundary.

The Provisioner doesn't need to know:

how the VPC was created
how subnet IDs were generated
which Terraform module created them
which environment-specific implementation produced them

It only consumes:

vpc_id
private_subnet_ids
database_subnet_ids
cluster_name

This is one of the most important improvements from the refactor.

15. Resolver Architecture

The Resolver is responsible for interpreting developer intent.

It does not create AWS infrastructure.

Developer input:

services = {
  payment-service = {
    runtime = "java"
    team    = "payments"

    persistence = {
      enabled      = true
      mode         = "new"
      engine       = "postgres"
      size         = "medium"
      database_name = "payment"
    }
  }
}

The Resolver turns this into normalized platform decisions.

16. Developer Persistence Contract

The supported persistence modes are:

none
new
temporary
existing
shared

Their meaning is:

Mode	Meaning
none	Application does not require database persistence
new	Create a new database
temporary	Create temporary/experimental database infrastructure
existing	Application needs access to an existing database
shared	Application needs access to a shared database

The developer declares intent.

The platform determines implementation.

17. Resolver Action Model

The Resolver now adds an explicit action.

Mapping:

none
   ↓
none

new
   ↓
create

temporary
   ↓
create

existing
   ↓
access

shared
   ↓
access

This was deliberately added because mode and action represent different concepts.

Mode

Describes the developer's intent.

Action

Describes what the platform needs to do.

For example:

mode = temporary
action = create

and:

mode = shared
action = access

This is a cleaner abstraction.

18. Resolved Service Structure

The Resolver produces approximately:

resolved_services = {
  service_name = {
    name        = service_name
    runtime     = service.runtime
    team        = service.team
    environment = var.environment

    application_security_group_name = ...

    persistence = {
      enabled       = ...
      mode          = ...
      action        = ...
      engine        = ...
      size          = ...
      database_name = ...
      access        = ...
    }
  }
}

This means downstream platform components don't have to repeatedly interpret raw developer intent.

19. Platform Actions

The Resolver exposes normalized platform actions.

Example:

payment-service
  application_security_group:
    enterprise-platform-dev-payment-service

  persistence:
    mode: new
    action: create
    engine: postgres
    size: medium
    database_name: payment

Another example:

customer-api
  persistence:
    mode: shared
    action: access
    database_name: customer
    access: read_write

This provides a clean contract between Resolver and Provisioner.

20. Resolver Validation

The developer contract validates:

Runtime

Examples include:

java
nodejs
python
Persistence mode
none
new
temporary
existing
shared
Database engine
postgres
mysql
aurora-postgres
aurora-mysql
mongodb
Size
small
medium
large
xlarge
Access
read
read_write

The contract also validates required combinations.

For example:

new and temporary require:

engine
size

existing and shared require:

database_name
access
21. Resolver Specialized Requests

The Resolver maintains specialized request collections.

Examples:

database_creation_requests
new_database_requests
temporary_database_requests

existing_database_requests
shared_database_requests

database_access_requests

This allows the Provisioner to act on the appropriate subset without reinterpreting developer input.

22. Approval Decision

The Resolver also identifies whether an access request requires approval.

The current conceptual policy is:

existing + read
    → lower friction

existing + read_write
    → approval

shared + read
    → lower friction

shared + read_write
    → approval

This is currently a platform decision, not yet a full production approval workflow.

The eventual architecture is:

Backstage
    ↓
Request
    ↓
Resolver
    ↓
Policy
    ↓
Approval
    ↓
Provisioner

Backstage should be the developer-facing control plane, but it should not itself become the policy authority.

23. Provisioner Architecture

The Provisioner receives:

project
environment
environment_context
services

The Provisioner does not determine what new, shared, etc. mean.

That has already been handled by the Resolver.

The Provisioner executes the resolved platform decisions.

24. Provisioner Environment Context

The Provisioner accepts:

variable "environment_context" {
  type = object({
    vpc_id              = string
    private_subnet_ids  = list(string)
    database_subnet_ids = list(string)
    cluster_name        = optional(string)
    jenkins_security_group_id = optional(string)
  })
}

This is the interface between an environment and the platform.

The design intentionally avoids exposing unnecessary infrastructure details.

25. Application Security Group Golden Path

Every application currently receives an application security group.

Example:

enterprise-platform-dev-payment-service
enterprise-platform-dev-fraud-service
enterprise-platform-dev-order-service
enterprise-platform-dev-reporting-service
enterprise-platform-dev-customer-api

The application security group module outputs:

security_group_id
security_group_name

The Provisioner consumes:

module.application_security_group[each.key].security_group_id

rather than assuming an output named id.

26. Database Golden Path

The Database Golden Path is responsible for creating database infrastructure when the Resolver determines:

action = create

The Provisioner currently creates the database module for:

local.database_creation_requests

The database receives:

project
environment
vpc_id
database_subnet_ids
database_name
engine
size
application_name
application_security_group_id
27. Database Architecture

The Database Golden Path currently supports:

PostgreSQL
MySQL
Aurora PostgreSQL
Aurora MySQL
DocumentDB/MongoDB

It maps developer-friendly sizes into infrastructure profiles.

Example:

small
medium
large
xlarge

are translated into actual AWS instance classes.

This means developers don't need to know:

db.t4g.medium
db.r6g.large
db.r6g.xlarge

The platform owns those implementation decisions.

28. Database Capacity vs Persistence Intent

A key architectural distinction:

Persistence intent
        ≠
Database capacity management

The developer declares:

I need a new database

and perhaps:

size = medium

The size represents the capacity profile for the new database.

It should not become a mechanism for automatically resizing existing databases.

Existing database capacity management is a separate platform concern.

29. Database Network Security

Each database receives its own security group.

The database security group allows inbound traffic from the application security group.

Example:

payment-service SG
        │
        │ TCP 5432
        ▼
payment database SG
        │
        ▼
PostgreSQL

For DocumentDB:

fraud-service SG
        │
        │ TCP 27017
        ▼
DocumentDB SG

This is preferable to allowing database access from broad CIDRs.

30. Database Subnets

Databases use:

environment_context.database_subnet_ids

rather than public subnets.

The environment therefore controls where databases are placed.

The Provisioner does not invent subnet IDs.

31. Database Credentials

The database Golden Path uses AWS Secrets Manager-managed master credentials.

The database resources use:

manage_master_user_password = true

This avoids putting database passwords directly into Terraform configuration.

The eventual application access model should build upon:

EKS workload identity
+
Secrets Manager
+
database-native authorization

rather than static credentials embedded in Git.

32. Logical Database Names vs AWS Physical Names

One important implementation issue occurred with:

fraud_experiment

The developer contract permits underscores.

AWS DocumentDB identifiers do not permit that form in the same way.

The first implementation attempted to use:

enterprise-platform-dev-fraud_experiment

which resulted in an AWS identifier validation failure.

We intentionally did not change the developer contract to prohibit underscores.

Instead, the Golden Path translates logical names into AWS-compatible physical identifiers.

Example:

Developer logical name:

fraud_experiment

             │
             ▼

Golden Path normalization

             │
             ▼

AWS physical identifier:

fraud-experiment

Implementation:

database_identifier = lower(
  replace(
    "${var.project}-${var.environment}-${var.database_name}",
    "_",
    "-"
  )
)

This is an important platform principle:

Developer-facing contracts should not be unnecessarily constrained by implementation-specific naming limitations.

The platform absorbs those differences.

33. Database Identifier vs Database Name

The architecture distinguishes between:

Logical database name
database_name = fraud_experiment

Used as the developer-facing logical identity.

Physical infrastructure identifier
enterprise-platform-dev-fraud-experiment

Used by AWS.

This distinction should be maintained throughout future Golden Paths.

34. Environment Database Policy

Database behavior is environment-aware.

Current defaults:

DEV
deletion_protection = false
multi_az = false
backup_retention = 7
STAGING
deletion_protection = true
multi_az = true
backup_retention = 7
PROD
deletion_protection = true
multi_az = true
backup_retention = 30

These are platform/environment policies.

Developers do not need to specify them.

35. Important Error: Wrong Security Group Output

During database provisioning, the Provisioner temporarily referenced:

module.application_security_group[service_name].id

The Application Security Group module did not expose id.

It exposed:

security_group_id
security_group_name

The incorrect reference was removed.

The correct reference is:

module.application_security_group[each.key].security_group_id

This reinforced an important rule:

Golden Path modules should expose explicit, semantic outputs rather than consumers guessing resource names.

36. Important Error: Stale Bootstrap Dependency

The Provisioning test originally contained stale Bootstrap remote-state inputs.

The Provisioner had been refactored to consume:

but the test still expected Bootstrap information.

This caused unnecessary coupling.

The test was rewritten to provide a fake environment context:

environment_context = {
  vpc_id = "vpc-test"

  private_subnet_ids = [
    "subnet-private-test-1",
    "subnet-private-test-2"
  ]

  database_subnet_ids = [
    "subnet-database-test-1",
    "subnet-database-test-2"
  ]

  cluster_name = "enterprise-platform-dev"
}

This correctly tests the Provisioner contract independently of Bootstrap.

37. Important Error: Provider Version Conflict

The Database module originally required:

AWS provider ~> 5.0

while the Provisioning test used:

AWS provider ~> 6.0

and the lock file contained AWS provider 6.x.

This produced a provider constraint conflict.

The Database module was standardized on:

AWS provider ~> 6.0

This aligned the module with the rest of the platform and the current lock file.

38. Important Error: DocumentDB Naming

The test originally attempted:

enterprise-platform-dev-fraud_experiment

for the DocumentDB identifier.

This was invalid.

The final implementation converts:

_

to:

-

for AWS physical identifiers.

The developer-facing contract remains unchanged.

39. Provisioning Test Strategy

The Provisioning test does not create actual AWS infrastructure.

It intentionally uses fake values:

vpc-test
subnet-private-test-1
subnet-private-test-2
subnet-database-test-1
subnet-database-test-2

The objective is to test:

Terraform syntax
Resolver output
Provisioner wiring
module dependencies
resource graph
Golden Path behavior
conditional creation
naming transformations

without incurring AWS costs.

40. Current Provisioning Test Matrix

The test currently contains:

payment-service
fraud-service
order-service
reporting-service
customer-api
Payment
runtime = java

persistence:
  enabled = true
  mode = new
  engine = postgres
  size = medium
  database_name = payment

Expected:

create PostgreSQL
Fraud
runtime = python

persistence:
  enabled = true
  mode = temporary
  engine = mongodb
  size = large
  database_name = fraud_experiment

Expected:

create DocumentDB
Order
persistence:
  enabled = false
  mode = none

Expected:

no database
Reporting
persistence:
  enabled = true
  mode = existing
  database_name = customer
  access = read

Expected:

access request
no database creation
Customer API
persistence:
  enabled = true
  mode = shared
  database_name = customer
  access = read_write

Expected:

access request
approval required
no database creation
41. Current Test Result

The latest test successfully completed:

terraform fmt
terraform validate
terraform plan

Validation returned:

Success! The configuration is valid.

The final Terraform plan returned:

Plan: 16 to add, 0 to change, 0 to destroy.

No actual infrastructure was applied.

This represents the current successful milestone for the Database Creation Golden Path.

42. What the 16 Resources Represent

The successful plan includes:

Application infrastructure

Five application security groups:

customer-api
fraud-service
order-service
payment-service
reporting-service
Payment database

PostgreSQL infrastructure including:

RDS instance
database subnet group
database security group
database security group rules
Fraud database

DocumentDB infrastructure including:

DocumentDB cluster
DocumentDB instance
subnet group
database security group
security group rules

The plan correctly produces no database creation for the existing and shared requests.

43. What We Have Proven

The current architecture has demonstrated:

Developer Contract
       ↓
Resolver
       ↓
Normalized Action
       ↓
Provisioner
       ↓
Application Golden Path
       ↓
Database Golden Path
       ↓
AWS resource graph

The most important thing is that the Provisioner does not have to understand raw developer intent.

44. Current Architecture Boundary

The responsibility boundaries are now:

Layer	Responsibility
Developer	Declare intent
Backstage	Developer control plane
Resolver	Interpret intent
Policy	Determine whether requested action is permitted
Approval	Obtain required authorization
Provisioner	Execute resolved action
Golden Path	Implement infrastructure pattern
Environment	Supply environment-specific context/policy
AWS	Execute infrastructure

This separation should be preserved.

45. Database Access Architecture — Next Stage

The next major implementation is the Database Access Golden Path.

It should not create a database for:

existing
shared

Instead it should create an access request.

Conceptually:

Developer
   │
   ▼
Resolver
   │
   ├── action = access
   ├── database = customer
   ├── access = read_write
   └── approval_required = true
   │
   ▼
Access Policy
   │
   ▼
Approval
   │
   ▼
Access Provisioner
   │
   ├── Network authorization
   ├── Database identity
   └── Secret access
46. Database Access Security Model

Database access should eventually consist of multiple authorization layers.

Layer 1 — Network

Application security group can reach the database security group.

Layer 2 — Workload Identity

The EKS application receives an AWS identity through workload identity/IRSA.

Layer 3 — Secrets Manager

The application identity can retrieve only the credentials/secrets it is authorized to use.

Layer 4 — Database Authorization

Database-native roles determine:

read

versus:

read_write

For example:

customer_read
    SELECT

customer_readwrite
    SELECT
    INSERT
    UPDATE
    DELETE

The exact implementation should be finalized when the Access Golden Path is built.

47. Environment Access Policy

We should not make permissions blindly identical across environments.

The preferred model is:

Application capability remains consistent, while environment policy controls whether and how that capability can be activated.

For example:

                     DEV       STAGE       PROD
--------------------------------------------------
read                  ✓          ✓           ✓
read_write            ✓          ✓           ⚠

Production read_write should require stronger policy and approval.

However, production should not arbitrarily invent a completely different application capability.

The intended capability should travel with the application through promotion:

DEV
 ↓
STAGING
 ↓
PROD

Production activation should be gated.

48. Promotion Philosophy

The platform should eventually enforce:

Developer Intent
      ↓
DEV
      ↓
Testing
      ↓
STAGING
      ↓
Validation
      ↓
PROD
      ↓
Production policy
      ↓
Approval
      ↓
Activation

This does not mean that production credentials automatically appear because DEV worked.

It means:

The same application requirement is promoted through the environments, while each environment applies its own security policy.

This creates progressive trust.

49. Backstage's Future Role

Backstage should become the developer-facing control plane.

Developers could eventually request:

Application
Environment
Database
Access level
Reason

For example:

application: customer-api
environment: prod
database: customer
access: read_write
reason: Customer transactions require database writes

Backstage submits the request.

It should not independently decide whether the request is allowed.

The platform policy layer remains authoritative.

50. Approval Architecture

The future approval flow is:

Backstage
    │
    ▼
Access Request
    │
    ▼
Resolver
    │
    ▼
Policy Evaluation
    │
    ├── no approval
    │       ↓
    │    Provision
    │
    └── approval required
            ↓
        Human approval
            ↓
        Provision

This allows approval rules to evolve without embedding them into Backstage.

51. What Should NOT Be Implemented Yet

The platform should not prematurely implement all of:

Backstage
approval engine
production promotion gates
database identity lifecycle
automatic revocation
full access catalog

before the underlying Access Golden Path contract is defined.

The correct sequence is:

1. Define access contract
2. Implement access resolver output
3. Implement access provisioner
4. Add environment policies
5. Add approval workflow
6. Connect Backstage
7. Add promotion gates

This avoids creating unnecessary coupling.

52. GitOps Relationship

The platform is designed to work with the existing GitOps architecture:

Jenkins
   ↓
Build
   ↓
Container
   ↓
ECR
   ↓
GitOps repository
   ↓
ArgoCD
   ↓
EKS

Jenkins is currently being used as the CI system.

The longer-term direction is migration toward GitHub Actions.

The Bootstrap architecture intentionally keeps Jenkins isolated enough that the CI migration does not require redesigning the environment architecture.

53. ArgoCD

ArgoCD is responsible for Kubernetes application deployment.

It is not responsible for:

AWS VPC creation
EKS creation
database creation
Terraform infrastructure decisions

The separation is:

Terraform
    ↓
Infrastructure

ArgoCD
    ↓
Kubernetes workloads
54. Golden Path Philosophy

A Golden Path should:

accept a small, stable interface
hide implementation complexity
enforce security defaults
apply environment policy
produce predictable resources
expose semantic outputs
avoid requiring developers to know AWS internals

Examples:

Application Golden Path
Database Golden Path
EKS Golden Path
Networking Golden Path
IAM Golden Path
Secrets Golden Path
55. What We Learned From the Refactor

Several architectural lessons came from the mistakes.

Lesson 1

Don't allow the Provisioner to know how environments are implemented.

Use:

environment_context

instead.

Lesson 2

Don't force developer contracts to match AWS implementation constraints.

Translate:

logical name

into:

physical identifier

inside the Golden Path.

Lesson 3

Use semantic module outputs.

Prefer:

security_group_id

over consumers assuming:

id
Lesson 4

Don't make NAT a developer concern.

It is environment infrastructure.

Lesson 5

Don't create VPC peering just because two systems are in different VPCs.

First determine whether the service already provides a secure connectivity mechanism.

Lesson 6

Don't make production permissions completely independent from application intent.

Carry the capability through promotion while applying stronger environment policy.

Lesson 7

Test the platform with fake environment context before applying infrastructure.

This catches architecture and dependency errors without creating AWS resources.

56. Current State

The platform currently has the following status:

BOOTSTRAP
    ✅ VPC
    ✅ Jenkins
    ✅ ECR
    ✅ IAM foundation
    ✅ Terraform state

ENVIRONMENT
    ✅ Environment-owned VPC
    ✅ Public/private/database subnets
    ✅ Environment-owned NAT
    ✅ EKS architecture
    ✅ Kubernetes subnet tagging

RESOLVER
    ✅ Developer contract
    ✅ Persistence modes
    ✅ Validation
    ✅ Action normalization
    ✅ Database request classification
    ✅ Access request classification
    ✅ Approval flag

PROVISIONER
    ✅ Environment context
    ✅ Application SG Golden Path
    ✅ Database creation Golden Path

DATABASE
    ✅ PostgreSQL
    ✅ MySQL
    ✅ Aurora definitions
    ✅ DocumentDB
    ✅ Database SG
    ✅ Database subnet groups
    ✅ Secrets Manager master credentials
    ✅ Environment defaults
    ✅ AWS identifier normalization

TESTING
    ✅ terraform fmt
    ✅ terraform validate
    ✅ terraform plan
    ✅ 16-resource test plan
    ✅ 0 changes
    ✅ 0 destroys
57. Immediate Next Work

The next implementation stage is:

Database Access Golden Path

Specifically:

existing
shared

requests.

The first target test should remain:

reporting-service
    existing
    customer
    read

customer-api
    shared
    customer
    read_write

Expected behavior:

reporting-service
    action = access
    approval_required = false
    database creation = false

customer-api
    action = access
    approval_required = true
    database creation = false
58. Future Platform Roadmap

After Database Access:

                    PLATFORM
                       │
        ┌──────────────┼───────────────┐
        │              │               │
        ▼              ▼               ▼
   Infrastructure   Application      Security
        │              │               │
        ▼              ▼               ▼
    Golden Paths    GitOps/ArgoCD    IAM/Secrets
        │
        ▼
    Database Access
        │
        ▼
    Environment Policy
        │
        ▼
      Approval
        │
        ▼
     Backstage
        │
        ▼
 Promotion Gates
        │
        ▼
 DEV → STAGE → PROD
59. Architectural Principle to Preserve

The most important principle from this refactor is:

Developers describe intent. The Resolver interprets intent. The Provisioner executes decisions. Golden Paths implement infrastructure. Environments provide context and policy.

We should avoid allowing these responsibilities to collapse back into a single Terraform layer.

60. Architecture Decision Summary
Decision	Status
Bootstrap separated from environments	Adopted
Environment-owned VPC	Adopted
Environment-owned NAT	Adopted
NAT exposed to developers	Rejected
VPC peering Bootstrap → DEV	Rejected
EKS public + private endpoint	Adopted
Jenkins accesses EKS through allowed public CIDR	Adopted
Resolver creates infrastructure	Rejected
Resolver interprets intent	Adopted
Provisioner consumes environment context	Adopted
Provisioner directly consumes Bootstrap state	Rejected
Explicit action in Resolver output	Adopted
Developer contract uses logical DB names	Adopted
AWS identifier normalization in Golden Path	Adopted
Application SG → Database SG	Adopted
Static DB credentials in Git	Rejected
Secrets Manager-managed credentials	Adopted
Database creation for existing	Rejected
Database creation for shared	Rejected
Access workflow for existing/shared	Next stage
Backstage as developer control plane	Target architecture
Environment-specific production policy	Target architecture
DEV → STAGE → PROD promotion gates	Target architecture
61. Current Milestone

Milestone: Platform Infrastructure Refactor + Database Creation Golden Path

Status:

SUCCESSFUL

The platform has moved from a more tightly coupled infrastructure implementation toward a reusable platform architecture based on:

Environment
    ↓
Environment Context
    ↓
Resolver
    ↓
Resolved Platform Actions
    ↓
Provisioner
    ↓
Golden Paths

The latest provisioning test validates successfully and produces:

16 to add
0 to change
0 to destroy

without applying infrastructure.

62. Live DEV Infrastructure Implementation

The previous milestone successfully validated the Resolver, Provisioner, and Database Creation Golden Path using a fake environment context and a Terraform plan that produced 16 resources without applying them. The next phase moved from structural validation to live AWS infrastructure validation.

The objective was to prove that the platform architecture could operate against a real environment while preserving the separation between Bootstrap, environment infrastructure, platform provisioning, and application delivery.

The implementation therefore introduced the DEV runtime temporarily, validated the Kubernetes/GitOps platform, validated auth-service connectivity, and then deliberately destroyed the expensive runtime resources while retaining the reusable DEV network foundation.

63. DEV Environment Configuration

The DEV environment was configured with:

project_name = "enterprise-platform"
environment = "dev"
cluster_name = "enterprise-platform-dev"
region = "us-east-1"
VPC CIDR = 10.10.0.0/16

The environment contains separate public, private, and database subnets. EKS worker nodes use the private subnets, while databases use the database subnets.

64. Live EKS Implementation

The EKS Golden Path was updated to the newer terraform-aws-modules/eks 21.x interface and the AWS provider 6.x generation. The EKS cluster was created as enterprise-platform-dev.

The worker-node design was:

Setting

Value

Node group

devops-nodes

Instance type

t3.medium

Capacity

ON_DEMAND

Minimum

2

Desired

3

Maximum

3

65. EKS Addon Ordering — VPC CNI Before Compute

A deliberate implementation change was made to ensure the VPC CNI addon is provisioned before managed worker compute. The EKS configuration uses before_compute = true for vpc-cni.

The reason is operational dependency ordering. Worker nodes require functional Kubernetes networking during bootstrap and operation. Establishing the CNI before compute reduces the risk that nodes are created before the cluster networking layer they depend on is ready.

The EKS addon set also includes CoreDNS, kube-proxy, and aws-ebs-csi-driver. The EBS CSI driver is integrated with IAM-backed service-account access.

66. EKS API Endpoint Design

The cluster was configured with both public and private EKS API endpoint access. Public access is restricted through an explicit CIDR allow-list.

This was an intentional alternative to creating permanent network connectivity between Bootstrap and DEV. Jenkins can reach the EKS API over HTTPS 443 when its current public IP is included in the allow-list.

67. EKS Access Troubleshooting

During validation, kubectl initially returned credential errors because the local AWS authentication context was not using the expected deployment role. The AWS profile was corrected to assume the Terraform deployment role, and STS identity was verified.

After correcting the identity path, the workstation could authenticate to the EKS API and use kubectl successfully.

The EKS access model therefore remained explicit: deployment roles receive cluster access through EKS access entries rather than relying on the identity that happened to create the cluster.

68. EKS Node Group Failure

The first live apply encountered a managed node-group failure. The node group entered CREATE_FAILED with NodeCreationFailure and unhealthy nodes.

At the same time, a separate Terraform resource failed while attempting to create a Jenkins-to-EKS security-group rule. These failures were deliberately treated as separate problems so that the node bootstrap failure was not incorrectly attributed to the security-group rule.

The node group was subsequently recovered and stabilized. Worker nodes eventually reported Ready and the required system workloads became operational.

69. Major Networking Error — Cross-VPC Security Group Reference

69.1 What Happened

Terraform attempted to create aws_security_group_rule.jenkins_to_eks by using the Jenkins security group as the source of an EKS security-group rule. AWS rejected the operation with an InvalidGroup.NotFound error indicating that the resources belonged to different networks.

69.2 Root Cause

Jenkins is located in the Bootstrap VPC, while EKS is located in the DEV VPC. Security groups are scoped to their VPC and cannot be directly referenced as though they were members of the same network.

69.3 Architectural Response

The invalid Jenkins-to-EKS security-group rule was removed. VPC peering was considered but rejected. The platform already has a secure EKS API endpoint mechanism, so introducing peering would have added unnecessary network coupling between Bootstrap and every environment.

The resulting design is:

Bootstrap VPC / Jenkins
        |
        | HTTPS 443 over controlled public EKS API access
        v
DEV EKS API endpoint

This preserves the intended VPC isolation while still allowing administrative access.

70. Load Balancer Controller and VPC Discovery

The AWS Load Balancer Controller was deployed through GitOps. An incorrect DEV VPC ID was initially present in the controller configuration, which caused subnet discovery problems.

The actual DEV VPC ID was verified and the controller configuration was corrected. After the correction, the controller successfully reconciled the Kubernetes ingress resources and created the expected AWS ALBs.

Two ingress paths were validated: ArgoCD and auth-service. ArgoCD returned HTTP 200 over HTTPS. auth-service first returned HTTP 503 because the backend was not healthy; after the backend recovered, the endpoint returned HTTP 404 from the application, proving that the request reached Spring Boot.

The hard-coded VPC ID remains technical debt. It should later be derived from environment context so the GitOps configuration is reusable across environments.

71. GitOps Platform Validation

The live DEV cluster was used to validate the existing GitOps platform. ArgoCD managed the Kubernetes workloads, while Terraform remained responsible for AWS infrastructure.

ArgoCD

AWS Load Balancer Controller

cert-manager

External DNS

External Secrets Operator

Prometheus

Alertmanager

Grafana

Loki

Promtail

kube-state-metrics

AWS EBS CSI driver

This validated the boundary already established in the architecture: Terraform provisions infrastructure; ArgoCD reconciles Kubernetes workloads.

72. External Secrets Failure

72.1 Initial Symptom

auth-service pods entered CreateContainerConfigError because auth-service-secret did not exist. The ExternalSecret resources for auth-service, Grafana, and Alertmanager reported SecretSyncedError.

72.2 Investigation

The ClusterSecretStore and External Secrets Operator were operational. The problem was not the Kubernetes External Secrets installation itself. The AWS Secrets Manager objects existed but did not have an available AWSCURRENT version that the operator could retrieve.

72.3 Why This Matters

A Secrets Manager resource existing in AWS is not equivalent to having a usable secret value. The runtime flow requires an actual current secret version.

72.4 Fix

The environment bootstrap-secrets.sh workflow was executed to populate the auth-service, Grafana, and Alertmanager secret values. The ExternalSecret resources were then force-reconciled using a timestamp annotation.

72.5 Result

The ExternalSecrets changed to SecretSynced=True. Kubernetes Secrets were created for auth-service, Grafana, and Alertmanager. auth-service pods subsequently became Running.

The intended runtime pattern remains:

AWS Secrets Manager -> External Secrets Operator -> Kubernetes Secret -> Application

73. Auth-Service End-to-End HTTP Validation

The auth-service endpoint initially returned 503 while the backend was unhealthy. After the secret synchronization problem was fixed and the pod became healthy, the same endpoint returned an HTTP 404 JSON response.

The 404 was interpreted correctly as an application-level response. It demonstrated that DNS, ALB, ingress, service routing, and the Spring Boot application were reachable. The requested route simply did not exist.

This created a useful validation ladder:

AWS infrastructure -> Kubernetes -> ingress -> ALB -> secret injection -> application -> database behavior

74. Auth-Service Database Status

The platform already has the Database Golden Path and database registry architecture described in the previous documentation. However, the current auth-service implementation has not yet been connected to a real PostgreSQL database.

Repository inspection did not identify an implemented PostgreSQL/JDBC/JPA/Flyway/Liquibase persistence layer. Therefore the existing database-related environment variables are configuration plumbing, not proof of active database persistence.

This is intentional for the next test: auth-service will become the real end-to-end consumer of the database provisioning platform.

75. Alertmanager and Helm Rendering Fixes

Helm configuration was changed to use tpl (.Files.Get ...) so embedded Helm expressions could be rendered.

alertmanager.smtp values were added to avoid nil-pointer rendering failures.

email.tmpl was created with email.subject and email.body after the template was undefined.

The Alertmanager template mount path was corrected to /etc/alertmanager/configmaps/alertmanager-templates/.

ExternalSecret YAML indentation was corrected when SMTP fields were added.

helm lint and helm template were used to validate chart rendering.

Sensitive SMTP values remain externalized in AWS Secrets Manager while GitOps controls configuration and templates.

76. Monitoring Validation and Node Exporter Issue

The monitoring stack became largely healthy. Prometheus, Alertmanager, Grafana, Loki, Promtail, and the associated operator components were running.

Two node-exporter DaemonSet pods remained Pending. Scheduler events reported a combination of pod-capacity and NodeAffinity constraints. This was treated as a separate scheduling/capacity issue rather than a failure of the monitoring stack itself.

The issue remains a follow-up item for the next EKS runtime window.

77. DEV Runtime Shutdown Strategy

After the live platform validation was completed, the DEV runtime was intentionally shut down to avoid paying for unused EKS and NAT resources.

The environment was changed to:

enable_eks = false
enable_nat_gateway = false

Terraform planned the destruction of the expensive runtime resources while retaining the DEV VPC and subnet foundation. The apply completed successfully with 55 resources destroyed.

78. What Terraform Destroyed

EKS cluster

EKS managed node group

EKS worker launch template/runtime resources

EKS addons

EKS cluster IAM/runtime resources

EKS IRSA/OIDC-related runtime resources

EKS cluster KMS resources

EKS runtime security groups and rules

EKS cluster CloudWatch log group

DEV NAT Gateway

NAT Gateway Elastic IP

The final Terraform outputs showed enable_eks=false, cluster_name=null, OIDC values null, and an empty NAT Gateway list, while the VPC and subnet outputs remained.

79. Manual Cleanup After EKS Destruction

The EKS cluster being destroyed does not automatically guarantee that every AWS resource previously created by Kubernetes controllers has been removed. Two Kubernetes-created ALBs remained in the DEV VPC after Terraform finished destroying EKS.

Those ALBs were manually deleted from AWS after confirming that the EKS runtime was gone.

This established a practical operational rule: after destroying a Kubernetes cluster, verify controller-created AWS resources independently.

80. EKS PVC EBS Volume Cleanup

An EBS inventory identified four unattached volumes whose Name tags followed the pattern enterprise-platform-dev-dynamic-pvc-*. These were dynamic Kubernetes persistent volumes created during the DEV runtime.

Because DEV was intentionally being shut down and the volumes were unattached, they were removed. A subsequent query for available EBS volumes returned no results.

This cleanup was performed separately from the persistent Jenkins storage so that disposable DEV storage was not mistaken for Bootstrap data.

81. Jenkins EBS Volumes and Network Interface

Two 30 GiB EBS volumes remain attached to the stopped Jenkins EC2 instance. One is explicitly named jenkins-data-volume; the other has no Name tag. These were retained because they belong to the persistent Bootstrap Jenkins environment.

The remaining network interface is the Jenkins EC2 instance's ENI in the Bootstrap VPC. It remains in-use by the stopped Jenkins instance and is therefore not an orphaned DEV EKS interface.

The ENI itself is not an EKS resource and is not something that should be deleted merely because DEV EKS was shut down.

82. Final Resource Lifecycle Model

Resource

Current state

Lifecycle decision

Bootstrap VPC

Retained

Persistent platform foundation

Jenkins EC2

Stopped

Retained for current CI platform

Jenkins EBS

Retained

Persistent Jenkins data

Jenkins ENI

Retained/in-use

Belongs to Jenkins

DEV VPC

Retained

Reusable environment foundation

DEV subnets

Retained

Reusable environment foundation

DEV EKS

Destroyed

Disposable runtime

DEV NAT

Destroyed

Disposable/costly runtime

DEV EKS PVC volumes

Deleted

Disposable runtime storage

DEV Kubernetes ALBs

Deleted

Controller-created runtime resources

83. What Has Been Proven by the Live Environment

The project has now validated two previously separate layers of the platform.

Layer 1 — Platform provisioning design:

Service Contract -> Resolver -> normalized platform actions -> Provisioner -> Golden Paths -> Terraform resource graph

Layer 2 — Live platform runtime:

AWS environment -> EKS -> GitOps -> ingress/load balancing -> secrets -> auth-service -> HTTP response

The next milestone is to join these two layers by making auth-service request and consume a real PostgreSQL database through the Service Contract.

84. Next Objective — Provision PostgreSQL for auth-service

The next test should use the existing platform architecture rather than introducing a new provisioning mechanism. auth-service will be the first service used to prove a complete infrastructure-to-application database lifecycle.

Illustrative Service Contract:

services:
  auth-service:
    runtime: spring-boot
    team: auth
    persistence:
      enabled: true
      mode: new
      engine: postgres
      size: small
      database_name: authdb
      access: read_write

The exact contract syntax should remain aligned with the implementation already documented. The important principle is that the developer specifies intent, not AWS implementation details.

85. Auth-Service Database Provisioning Flow

The Service Contract declares that auth-service needs a new PostgreSQL database.

The Resolver validates the contract.

The Resolver derives namespace from team=auth.

The Resolver converts persistence mode=new into action=create.

The Resolver produces the normalized database creation request.

The Provisioner consumes the resolved request and environment_context.

The Application Security Group Golden Path supplies the application security-group ID.

The Database Golden Path receives the environment VPC, database subnets, database name, engine, size, and application security-group ID.

Terraform creates the PostgreSQL/RDS infrastructure.

The database security group allows PostgreSQL access from the auth-service application security group.

The database credentials are managed through AWS Secrets Manager rather than Git.

The database registry records the logical database and physical AWS resource information.

The secret-resolution path provides the required database connection information to the workload.

External Secrets synchronizes the approved secret information into Kubernetes.

auth-service is updated to implement actual PostgreSQL persistence.

The application pipeline builds and deploys the updated auth-service image.

ArgoCD reconciles the application into EKS.

An end-to-end test creates and retrieves real application data from PostgreSQL.

86. Expected Database Architecture

                    Service Contract
                           |
                           v
                        Resolver
                           |
                    action = create
                           |
                           v
                      Provisioner
                           |
              +------------+-------------+
              |                          |
              v                          v
       Application SG             Database Golden Path
                                         |
                              +----------+----------+
                              |          |          |
                              v          v          v
                            RDS       DB SG     Subnet Group
                              |
                              v
                       Database Registry
                              |
                              v
                       Secrets Manager
                              |
                              v
                    External Secrets
                              |
                              v
                      Kubernetes Secret
                              |
                              v
                        auth-service
                              |
                              v
                     PostgreSQL/RDS

87. Infrastructure Pipeline and Application Pipeline

The platform must maintain two separate but connected pipelines.

87.1 Infrastructure / Platform Pipeline

Service Contract -> Git -> Platform Pipeline -> Resolver -> Provisioner -> Terraform -> AWS/EKS

This pipeline is responsible for infrastructure changes such as requesting a database, secret, identity, network capability, or other platform resource.

87.2 Application Delivery Pipeline

Application Git -> Jenkins -> build/test/security scans -> Docker -> ECR -> GitOps repository -> ArgoCD -> EKS

This pipeline is responsible for releasing application code. A normal application image release should not invoke Terraform simply because the container image changed.

88. Why the Two Pipelines Matter

The infrastructure lifecycle and application lifecycle operate at different speeds. Infrastructure changes require platform policy, Terraform planning, and potentially approval. Application releases should remain independent and use the established CI/CD and GitOps path.

This separation also makes the eventual Backstage architecture cleaner: Backstage creates or updates the developer-facing Service Contract, while the platform automation determines and executes infrastructure changes.

89. Database Access Golden Path After Database Creation

Once auth-service database creation is proven, the existing existing/shared database access model can be completed.

For existing/shared requests, the Resolver should continue to produce action=access rather than action=create.

The intended flow is:

Service Contract -> Resolver -> access request -> policy evaluation -> approval when required -> access provisioner

This prevents services from accidentally creating duplicate databases when they only need access to a registered database.

90. Security Model for Database Access

The database architecture should continue to use multiple security layers:

Network layer: application security group can reach database security group on TCP 5432.

Workload identity layer: the application workload receives its intended AWS identity.

Secrets layer: only the authorized workload/secret mechanism can retrieve the required credentials.

Database authorization layer: PostgreSQL roles determine read versus read_write capabilities.

This preserves the principle established in the previous documentation that access is not a single permission. Network connectivity, cloud identity, secret access, and database authorization are separate controls.

91. Backstage Transition Plan

Backstage remains the target developer-facing control plane, but it should be introduced after the underlying Service Contract and Golden Paths are proven against real infrastructure.

The target flow is:

Backstage -> Service Contract -> Git -> Platform Pipeline -> Resolver -> Policy/Approval -> Provisioner -> Terraform -> AWS/EKS

Backstage should not become the place where AWS-specific implementation logic lives. Its responsibility is to provide a developer-friendly interface for expressing intent and submitting changes.

92. Why Backstage Comes Last in This Phase

The Service Contract must first be proven.

The Resolver must correctly interpret the contract.

The Provisioner must execute resolved actions.

The Database Golden Path must create real infrastructure.

Secret and workload access must work.

auth-service must successfully persist data.

Only then should Backstage be placed in front of the platform.

This sequence reduces debugging complexity and prevents the developer portal from becoming a workaround for an unproven platform backend.

93. Remaining Technical Debt

Make the AWS Load Balancer Controller VPC configuration environment-derived instead of hard-coded.

Investigate node-exporter scheduling/capacity constraints when EKS is recreated.

Implement actual PostgreSQL persistence in auth-service.

Execute the auth-service Service Contract against real DEV infrastructure.

Complete database registry validation with a real RDS resource.

Complete the database secret-resolution path with real application credentials.

Validate least-privilege workload/secret access.

Complete the Database Access Golden Path for existing/shared databases.

Continue the planned Jenkins-to-GitHub-Actions migration without redesigning the platform.

Introduce Backstage after the platform provisioning path is proven.

94. Lessons Learned From the Live Implementation

EKS addon ordering should be explicit when worker bootstrap depends on cluster networking.

AWS resource relationships must respect service boundaries such as VPC-scoped security groups.

VPC isolation should not be weakened simply because an administrative component needs access to the EKS API.

A missing AWSCURRENT secret version can break Kubernetes workloads even when the Secrets Manager object itself exists.

Kubernetes controllers can create AWS resources whose lifecycle needs independent post-destruction verification.

A 404 from the application can be a successful infrastructure test when the goal is to prove end-to-end request reachability.

Disposable DEV runtime and persistent Bootstrap infrastructure should have different lifecycle policies.

Real infrastructure validation should follow successful fake-context Terraform tests, not replace them.

The platform should absorb AWS implementation constraints rather than forcing those constraints into the developer-facing contract.

The Resolver/Provisioner boundary must remain intact as more automation is added.

95. Current Platform State

BOOTSTRAP
  VPC                    Retained
  Jenkins                Stopped / retained
  Jenkins EBS            Retained
  Jenkins ENI            Retained
  Terraform state        Retained
  Shared foundation      Retained

DEV FOUNDATION
  VPC                    Retained
  Public subnets         Retained
  Private subnets        Retained
  Database subnets       Retained

DEV RUNTIME
  EKS                    Destroyed after validation
  NAT                    Destroyed after validation
  ALBs                   Deleted after EKS shutdown
  Dynamic PVC volumes    Deleted

PLATFORM LOGIC
  Resolver               Implemented
  Provisioner             Implemented
  Environment context     Implemented
  Application SG path     Implemented
  Database create path    Implemented / structurally validated
  Database access path    Next implementation stage

APPLICATION
  auth-service            Live validation completed
  PostgreSQL persistence  Not yet implemented

DEVELOPER EXPERIENCE
  Service Contract        Implemented conceptually / Git-based testable
  Backstage               Target architecture / not yet introduced

96. Current Milestone

Milestone: Live DEV Platform Validation + Preparation for End-to-End Database Provisioning

Status: SUCCESSFUL CHECKPOINT

The platform has now moved beyond a Terraform-only design exercise. The live implementation validated the environment architecture, EKS, Kubernetes networking, access, GitOps, ingress, secrets delivery, application reachability, monitoring, and controlled environment shutdown.

The next milestone is to connect the already-tested Database Creation Golden Path to the real auth-service Service Contract and prove actual PostgreSQL persistence end to end.

97. Next Session Execution Plan

Re-enable DEV EKS and NAT only for the controlled testing window.

Validate EKS, addons, worker nodes, ArgoCD, External Secrets, ingress, and required platform services.

Create the auth-service Service Contract with PostgreSQL persistence requirements.

Run Terraform Resolver validation and inspect the normalized action.

Confirm the Provisioner receives environment_context rather than Bootstrap internals.

Provision PostgreSQL through the existing Database Golden Path.

Validate the database security-group relationship with auth-service.

Validate database registration and physical AWS identifiers.

Validate Secrets Manager and External Secrets integration.

Implement real PostgreSQL persistence in auth-service.

Build and publish the updated application through Jenkins/ECR.

Update the GitOps deployment and allow ArgoCD to reconcile.

Run a real application persistence test.

Document the complete end-to-end Golden Path.

Then begin the Backstage implementation on top of the proven platform.

98. Final Architectural Principle

The architecture established in the previous documentation remains unchanged at its core:

Developers describe intent. The Resolver interprets intent. Policy determines what is permitted. The Provisioner executes resolved decisions. Golden Paths implement infrastructure. Environments provide context and policy. Terraform manages infrastructure. ArgoCD manages Kubernetes workloads. Backstage will eventually provide the developer-facing control plane.

The live implementation did not replace this architecture. It validated it under real AWS and Kubernetes conditions and identified the remaining work required to prove the complete database provisioning lifecycle.

End of comprehensive continuation — 8 September 2026