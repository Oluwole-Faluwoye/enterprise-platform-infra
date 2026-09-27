Enterprise Platform Infrastructure

Platform Architecture, Refactoring & Provisioning Design

Project: Enterprise Platform Infrastructure

Repository: enterprise-platform-infra

Primary Cloud: AWS

Primary Region: us-east-1

Architecture Status: Refactored Foundation / Golden Path Implementation

Last Updated: September 2026

1. Purpose

This document describes the architecture, design decisions, refactoring
work, implementation patterns, testing approach, mistakes encountered,
and fixes made while building the Enterprise Platform Infrastructure.

The goal is to create a reusable internal platform capable of allowing
application teams to express what they need without requiring them to
understand or directly manage the underlying AWS infrastructure.

The platform is being designed around the following principles:

Developers declare intent rather than infrastructure.

Environment infrastructure is owned by the environment.

Platform logic interprets developer intent.

Golden Paths implement approved infrastructure patterns.

Environment-specific context is supplied to the platform rather than
hard-coded into developer requests.

Security and access decisions are separated from infrastructure
creation.

Infrastructure should be reusable across DEV, STAGING, and PROD.

The platform should support progressive automation without requiring a
redesign later.

2. Repository Structure

The current repository structure is:

enterprise-platform-infra/

│

├── environments/

│   ├── bootstrap/

│   ├── dev/

│   ├── staging/

│   └── prod/

│

├── modules/

│   ├── acm/

│   ├── application-security-group/

│   ├── database/

│   ├── ecr/

│   ├── eks/

│   ├── iam-bootstrap/

│   ├── iam-irsa/

│   ├── jenkins/

│   ├── networking/

│   ├── route53/

│   └── secrets-manager/

│

├── platform/

│   ├── resolver/

│   └── provisioning/

│

└── docs/

    └── architecture/

The architecture intentionally separates:

Environment

Module

Resolver

Provisioner

rather than placing all infrastructure decisions inside environment
Terraform.

3. Target Architecture

The target architecture is:

                         DEVELOPER

                             │

                             │

                       Developer Intent

                             │

                             ▼

                       ┌───────────┐

                       │  Backstage │

                       │ (Control   │

                       │   Plane)   │

                       └─────┬─────┘

                             │

                             ▼

                    ┌─────────────────┐

                    │     RESOLVER    │

                    │                 │

                    │ Interpret intent│

                    │ Apply platform  │

                    │ rules           │

                    └────────┬────────┘

                             │

                     Resolved Actions

                             │

                             ▼

                    ┌─────────────────┐

                    │   PROVISIONER   │

                    │                 │

                    │ Execute actions │

                    │ using environment│

                    │ context         │

                    └────────┬────────┘

                             │

                ┌────────────┼────────────┐

                │            │            │

                ▼            ▼            ▼

             Golden       Golden       Golden

              Path         Path         Path

              VPC          EKS        Database

                │            │            │

                └────────────┼────────────┘

                             │

                             ▼

                       AWS Resources

The important architectural boundary is:

Resolver decides what should happen. Provisioner makes it happen.

4. Environment Architecture

The platform separates the shared Bootstrap foundation from individual
application environments.

                        AWS ACCOUNT

                            │

             ┌──────────────┴──────────────┐

             │                             │

             ▼                             ▼

        BOOTSTRAP                      ENVIRONMENTS

             │                             │

      ┌──────┼──────┐             ┌───────┼────────┐

      │      │      │             │       │        │

     VPC   Jenkins ECR           DEV   STAGING    PROD

      │                             │

      │                             ├── VPC

      │                             ├── NAT

      │                             ├── EKS

      │                             ├── ArgoCD

      │                             └── workloads

      │

      └── Shared platform foundation

Bootstrap

Bootstrap exists to provide infrastructure that supports the platform
itself.

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

Jenkins does not require NAT because it is deployed in a public subnet
and can use its public connectivity.

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

This prevents Bootstrap from becoming a dependency for the lifecycle of
application environments.

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

A previous implementation risk was having Kubernetes-specific subnet
tags embedded into generic networking.

The networking module was generalized.

The module now accepts:

variable "enable_kubernetes_tags" {

  type    = bool

  default = false

}

and:

variable "cluster_name" {

  type    = string

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

This keeps the networking module reusable for non-Kubernetes
infrastructure.

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

cluster_endpoint_public_access  = true

cluster_endpoint_private_access = true

Public API access is restricted to explicitly allowed CIDRs.

10. EKS Connectivity Decision

A VPC peering approach between Bootstrap and DEV was considered.

It was ultimately rejected.

The reason is that the EKS cluster already supports:

Public API endpoint

+

Private API endpoint

and Jenkins can access the EKS public API endpoint when its public IP is
allowed.

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

This simplified the architecture and eliminated unnecessary network
coupling.

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

The environment can consume selected Bootstrap outputs through Terraform
remote state.

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

However, the platform Provisioner itself should not depend on Bootstrap
remote state.

This distinction became important during the refactor.

13. Major Architecture Refactor

The previous architecture allowed the provisioning layer to depend
directly on Bootstrap state.

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

    vpc_id              = module.networking.vpc_id

    private_subnet_ids  = module.networking.private_subnets

    database_subnet_ids = module.networking.database_subnets

    cluster_name        = var.cluster_name

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

    team    = "payments"

    persistence = {

      enabled      = true

      mode         = "new"

      engine       = "postgres"

      size         = "medium"

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

Mode  Meaning

none  Application does not require database persistence

new Create a new database

temporary Create temporary/experimental database infrastructure

existing  Application needs access to an existing database

shared  Application needs access to a shared database

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

This was deliberately added because mode and action represent different
concepts.

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

    name        = service_name

    runtime     = service.runtime

    team        = service.team

    environment = var.environment

    application_security_group_name = ...

    persistence = {

      enabled       = ...

      mode          = ...

      action        = ...

      engine        = ...

      size          = ...

      database_name = ...

      access        = ...

    }

  }

}

This means downstream platform components don't have to repeatedly
interpret raw developer intent.

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

This allows the Provisioner to act on the appropriate subset without
reinterpreting developer input.

22. Approval Decision

The Resolver also identifies whether an access request requires
approval.

The current conceptual policy is:

existing + read

    → lower friction

existing + read_write

    → approval

shared + read

    → lower friction

shared + read_write

    → approval

This is currently a platform decision, not yet a full production
approval workflow.

Application / Platform Responsibility Boundary

The platform is responsible for infrastructure capabilities and secure
delivery.

The application is responsible for application behavior and application
schema.

Platform-owned: - AWS infrastructure - EKS - networking - application
Security Groups - database infrastructure - database Security Groups -
Secrets Manager integration - workload identity - database registry -
Kubernetes delivery primitives - environment policy

Application-owned: - application code - database schema - tables -
indexes - constraints - application-specific seed/reference data -
schema migrations

The platform should not hard-code application tables into the generic
Database Golden Path.

Database Access Architecture

The platform distinguishes between creating a database and requesting
access to an existing database.

For:

mode = new
mode = temporary

the Resolver produces:

action = create

For:

mode = existing
mode = shared

the Resolver produces:

action = access

The Provisioner must not create a database for an existing/shared
request.

The intended access flow is:

Service Contract
    ↓
Resolver
    ↓
action = access
    ↓
Policy evaluation
    ↓
Approval when required
    ↓
Access Provisioner
    ↓
Network authorization
Workload identity
Secret access
Database authorization

25. Environment Context Boundary

The Provisioner must not know how an environment is implemented.

The environment supplies a controlled environment_context containing the
infrastructure information required by the Provisioner.

Conceptually:

Environment
    ↓
environment_context
    ↓
Provisioner

The Provisioner consumes semantic values such as:

vpc_id
private_subnet_ids
database_subnet_ids
cluster_name
vpc_cidr

It does not depend directly on Bootstrap internals or assume how the VPC
or subnets were created.

Golden Path Philosophy

A Golden Path should:

accept a small, stable interface

hide implementation complexity

enforce security defaults

apply environment policy

produce predictable resources

expose semantic outputs

avoid requiring developers to know AWS implementation details

Current Golden Paths include:

Networking

EKS

Application Security Group

Database

IAM / workload identity

Secrets

Route53 / DNS

ACM

Application delivery

Live DEV Environment

The DEV environment is currently active for the present implementation
and validation window.

Configuration:

project = enterprise-platform
environment = dev
region = us-east-1
VPC CIDR = 10.10.0.0/16
cluster = enterprise-platform-dev

DEV owns:

VPC
public subnets
private subnets
database subnets
NAT
EKS
environment-specific runtime resources

Bootstrap remains separate and retained.

The DEV runtime can still be shut down for cost control using:

enable_eks = false
enable_nat_gateway = false

The DEV VPC/subnet foundation is retained independently of the expensive
runtime.

EKS Runtime

Current live EKS configuration:

Cluster:
    enterprise-platform-dev

Region:
    us-east-1

Kubernetes:
    1.34.10

Managed node group:
    devops_nodes

Instance type:
    m5.large

Desired:
    3

Minimum:
    2

Maximum:
    3

The EKS API uses public and private endpoint access, with public access
restricted through an explicit CIDR allow-list.

The VPC CNI is configured for Security Groups for Pods.

Security Groups for Pods

The platform uses AWS Security Groups for Pods for application-level
network identity.

auth-service uses:

application Security Group:
    enterprise-platform-dev-auth-service

Security Group ID:
    sg-092eb850b231b34be

The Kubernetes SecurityGroupPolicy associates the auth-service workload
with this application Security Group.

The VPC CNI configuration includes:

ENABLE_POD_ENI = true
POD_SECURITY_GROUP_ENFORCING_MODE = standard

The RDS Security Group permits PostgreSQL access from the application
Security Group rather than from the broad worker-node Security Group.

Application Security Group Egress

The Application Security Group Golden Path was extended to provide
controlled egress for:

UDP 53 → VPC DNS
TCP 53 → VPC DNS
TCP 443 → required AWS/external endpoints
TCP 5432 → platform-managed PostgreSQL database

The database-specific rule references the database Security Group rather
than opening database access broadly.

CoreDNS / Pod DNS Path

Moving workloads to Security Groups for Pods exposed a DNS path that
required an environment-level rule.

The application Security Group needed to reach CoreDNS running on EKS
worker nodes.

The environment composition layer therefore permits:

Application SG
    ↓
TCP 53 / UDP 53
    ↓
EKS Node SG
    ↓
CoreDNS

This relationship is intentionally implemented in the environment
composition layer rather than adding an application dependency to the
foundational EKS module.

The change was committed as:

5500a34
Allow application pods to access CoreDNS

The infrastructure pipeline successfully deployed the change.

PostgreSQL Database Golden Path

The Database Golden Path provisions platform-managed PostgreSQL
infrastructure.

For auth-service the live database is:

RDS:
    enterprise-platform-dev-authdb

Database:
    authdb

Engine:
    PostgreSQL

Port:
    5432

Endpoint:
    enterprise-platform-dev-authdb.c5wqkyiq8ame.us-east-1.rds.amazonaws.com

The database uses private database subnets.

The database Security Group permits access from the auth-service
application Security Group.

Database Registry

The database registry provides the platform with a logical-to-physical
representation of managed databases.

The registry records semantic information such as:

logical database name
engine
environment
owner team
resource identifier
endpoint
port
credential reference
status

This allows later services to request access using a logical database
name rather than an AWS RDS identifier.

Secrets Manager

Database credentials are managed through AWS Secrets Manager.

The application receives a credential reference rather than a static
password stored in Git.

The intended runtime path is:

AWS Secrets Manager
    ↓
External Secrets / secret synchronization
    ↓
Kubernetes Secret / application configuration
    ↓
auth-service
    ↓
PostgreSQL

The platform separates secret management from application source code.

Workload Identity

auth-service uses its platform-created workload identity:

enterprise-platform-dev-auth-service-database

The workload receives AWS permissions through EKS workload identity /
IRSA.

The identity is scoped to the resources the workload is intended to
access.

This keeps AWS credentials out of the application image and Git
repository.

Auth-Service Live State

auth-service is currently deployed in:

namespace = identity

The deployment has:

desired replicas = 2
available replicas = 2
unavailable replicas = 0

The workload is Running and Ready.

The Kubernetes Service is:

auth-service:8080

The application is a Spring Boot service.

Auth-Service PostgreSQL Connectivity --- LIVE VERIFIED

The auth-service application is now connected to the
platform-provisioned PostgreSQL database.

The application health endpoint reports:

status = UP
db = UP
database = PostgreSQL
livenessState = UP
readinessState = UP

This is live runtime validation rather than a Terraform-only plan.

Verified path:

auth-service Pod
    ↓
Application Security Group
    ↓
DNS / CoreDNS
    ↓
RDS Security Group
    ↓
PostgreSQL
    ↓
Spring Boot datasource

38. ALB / Ingress --- LIVE VERIFIED

The auth-service ingress is operational.

Host:

api.dev.dreammyles.online

The ingress uses an internet-facing AWS Application Load Balancer with:

target-type = ip
HTTP = 80
HTTPS = 443
HTTP → HTTPS redirect
ACM certificate

HTTP requests redirect to HTTPS.

HTTPS requests reach Spring Boot.

A request to an undefined route returns HTTP 404. This is an
application-level response and proves the request reached the service.

The application health endpoint is reachable over HTTPS and reports
PostgreSQL as UP.

Route53 and ACM --- LIVE VERIFIED

Bootstrap owns the root DNS architecture.

Root:

dreammyles.online

DEV child zone:

dev.dreammyles.online

The DEV child zone is delegated from the root zone.

The ACM certificate covers:

*.dev.dreammyles.online
dev.dreammyles.online

The auth-service hostname:

api.dev.dreammyles.online

is therefore covered by the certificate.

ExternalDNS

ExternalDNS integrates Kubernetes ingress resources with the DEV Route53
child zone.

The auth-service hostname resolves to the AWS ALB.

This keeps DNS records derived from Kubernetes resources rather than
requiring developers to manage individual AWS record identifiers.

ArgoCD / GitOps

ArgoCD is responsible for Kubernetes workload reconciliation.

Terraform is responsible for AWS infrastructure.

The application delivery flow remains:

Application Git
    ↓
Jenkins
    ↓
Build / test / security checks
    ↓
Docker
    ↓
ECR
    ↓
GitOps repository
    ↓
ArgoCD
    ↓
EKS

The infrastructure flow remains separate:

Service Contract
    ↓
Platform pipeline
    ↓
Resolver
    ↓
Provisioner
    ↓
Terraform
    ↓
AWS

An application image release should not invoke Terraform merely because
application code changed.

Current Platform Applications

The live DEV ArgoCD environment includes the core platform applications:

auth-service
aws-load-balancer-controller
cert-manager
external-dns
external-secrets
external-secrets-platform
loki
monitoring-assets
prometheus-crds
prometheus-stack
promtail
root-app
storage

The platform controllers and auth-service are currently reconciled
through ArgoCD.

Current Platform State

BOOTSTRAP

VPC                         Retained
Jenkins                     Stopped / retained
Jenkins EBS                 Retained
Jenkins ENI                 Retained
Terraform state             Retained
Root Route53 zone            Retained
DEV Route53 child zone       Retained
Shared foundation            Retained

DEV FOUNDATION

VPC                         Active / retained
Public subnets              Active / retained
Private subnets             Active / retained
Database subnets             Active / retained

DEV RUNTIME

NAT                         Active
EKS                         Active
ArgoCD                      Active
Platform controllers        Active
auth-service                Active
PostgreSQL RDS              Active
ALB                         Active

PLATFORM LOGIC

Resolver                    Implemented
Provisioner                 Implemented
Environment context         Implemented
Application SG path         Implemented
SG-for-Pods path            Implemented
Database create path        Implemented
Database registry           Implemented
Secret resolution           Implemented
Workload identity           Implemented
Database access path        Next major implementation

44. What Has Been Proven

The platform has now joined the previously separate platform-design and
live-runtime layers.

Platform layer:

Service Contract
    ↓
Resolver
    ↓
Normalized Action
    ↓
Provisioner
    ↓
Golden Paths
    ↓
Terraform
    ↓
AWS resource graph

Runtime layer:

Environment
    ↓
EKS
    ↓
ArgoCD
    ↓
Security Groups for Pods
    ↓
Secrets / workload identity
    ↓
ALB / Route53 / ACM
    ↓
auth-service
    ↓
PostgreSQL

45. Database Infrastructure vs Application Schema

The platform owns database infrastructure.

The application owns its schema.

Platform:

RDS
database
subnet placement
database Security Group
network authorization
credentials
Secrets Manager integration
workload identity
registry
connection metadata

Application:

schemas
tables
indexes
constraints
application-specific roles
seed/reference data
schema evolution

Terraform should not become the owner of application tables.

Migration Capability --- NEXT

The next database lifecycle capability is automated application schema
migration.

For Spring Boot auth-service, the initial implementation will use
Flyway.

Target:

PostgreSQL ready
    ↓
Migration step
    ↓
Flyway
    ↓
V1 / V2 / V3 ...
    ↓
Schema ready
    ↓
auth-service
    ↓
Application traffic

The platform should provide the migration capability without
understanding application-specific SQL.

Migration Ownership Model

The application owns migration definitions.

Example:

auth-service
    migrations/
        V1__initial_schema.sql
        V2__create_roles.sql
        V3__create_permissions.sql

The platform does not hard-code those tables.

Conceptually, the Service Contract may include:

migration:
  enabled: true
  strategy: flyway

The exact contract syntax should be finalized before implementation.

Controlled Migration Execution

Migrations should not independently execute from every application
replica during startup.

The preferred initial approach is a controlled migration Job or
equivalent deployment step.

Target:

RDS ready
    ↓
Migration Job
    ↓
Flyway
    ↓
Migration success
    ↓
auth-service Deployment
    ↓
Readiness
    ↓
ALB traffic

The final ArgoCD hook/sync-wave mechanism should be selected during
implementation.

Application-Specific Database Requirements

The platform should not encode application-specific schemas.

auth-service might require:

users
roles
permissions
sessions

Another service might require completely different tables.

The generic database capability remains unchanged.

The application supplies the migration package that creates and evolves
its own schema.

Runtime and Persistence Are Independent

The platform should model runtime and persistence independently.

Examples:

runtime: spring-boot
persistence:
  engine: postgres

and:

runtime: nodejs
persistence:
  engine: postgres

The runtime capability controls build/deployment/runtime behavior.

The persistence capability controls database infrastructure and access.

The migration capability controls application schema lifecycle.

Developer Service Contract

The Service Contract should expose stable capabilities.

The developer should specify:

project
environment
service.name
team
runtime
persistence
database engine
capacity profile
access mode
migration capability

The developer should not specify:

AWS subnet IDs
AWS Security Group IDs
RDS instance classes
IAM role ARNs
Secret ARNs
ALB IDs

The platform resolves these implementation details.

Database Access Golden Path --- LATER

The Database Access Golden Path remains required for:

existing
shared

requests.

It should create access requests rather than databases.

Target:

Service Contract
    ↓
Resolver
    ↓
action = access
    ↓
Policy
    ↓
Approval if required
    ↓
Access Provisioner
    ↓
Network authorization
Database identity
Secret access
Database-native authorization

This follows the core new-database lifecycle work.

Database Access Security Model

Database access remains a layered security problem.

Layer 1 --- Network:

Application SG → Database SG → TCP 5432

Layer 2 --- Workload identity:

EKS workload → intended AWS identity

Layer 3 --- Secrets:

Workload → authorized database credentials

Layer 4 --- Database authorization:

PostgreSQL role → read/read_write capability

These are separate controls and should remain separate.

Backstage --- FUTURE

Backstage remains the target developer-facing control plane.

The intended future flow is:

Backstage
    ↓
Service Contract
    ↓
Git / platform request
    ↓
Resolver
    ↓
Policy / Approval
    ↓
Provisioner
    ↓
Terraform / GitOps
    ↓
AWS / EKS

Backstage should provide the developer interface.

It should not contain AWS-specific provisioning logic or become the
authoritative policy engine.

Why Backstage Comes Later

The platform should first prove:

Service Contract
Resolver
Provisioner
Golden Paths
PostgreSQL lifecycle
migration
application persistence
application delivery

Only then should Backstage be placed in front of the platform.

This prevents the developer portal from becoming a workaround for an
unproven platform backend.

Current Technical Debt / Follow-Up

Formalize migration capability in the Service Contract.

Implement Flyway for auth-service.

Define auth-service V1 schema.

Execute migrations automatically during deployment.

Verify schema and tables in a fresh PostgreSQL database.

Implement real auth-service CRUD persistence.

Prove a fresh platform-provisioned database becomes
application-ready without manual SQL.

Generalize the Spring Boot + PostgreSQL Golden Path.

Implement Node.js + PostgreSQL using the same persistence
capability.

Complete Database Access Golden Path for existing/shared databases.

Validate least-privilege database-native roles.

Continue Jenkins → GitHub Actions migration.

Address remaining monitoring/node-exporter scheduling constraints
when required.

Introduce Backstage after the backend workflow is stable.

Current Acceptance Test

The next milestone is complete only when:

Service Contract
    ↓
Resolver
    ↓
Provisioner
    ↓
PostgreSQL infrastructure
    ↓
Database ready
    ↓
Migration
    ↓
Schema created
    ↓
Application deployed
    ↓
Application Ready
    ↓
Application creates data
    ↓
Application reads data
    ↓
PostgreSQL retains data

The strongest proof is:

A fresh platform-provisioned database becomes application-ready automatically, without manual SQL, and the application successfully creates and retrieves real data.

58. Current Milestone

Milestone:

Live DEV Platform + End-to-End Infrastructure and Runtime Validation

Status:

SUCCESSFUL

Validated:

Bootstrap/environment separation
environment-owned networking
EKS
VPC CNI
Security Groups for Pods
Application Security Groups
CoreDNS path
RDS PostgreSQL
Database Security Groups
workload identity
Secrets Manager
ArgoCD
AWS Load Balancer Controller
Route53
ACM
ExternalDNS
HTTPS ingress
Spring Boot application
Kubernetes Service routing
PostgreSQL application connectivity
application health/readiness

Remaining major capability:

Application Database Lifecycle
    ↓
Migration
    ↓
Schema initialization
    ↓
Real application CRUD persistence

59. Recent Change Ledger

Application Security Group - Added controlled DNS, HTTPS, and database
egress. - Status: implemented and live verified.

EKS/CoreDNS network path - Added TCP/UDP 53 ingress from application
Security Groups to the EKS node Security Group at the environment
composition layer. - Status: implemented, committed, deployed, and
verified.

Security Groups for Pods - Enabled Pod ENI support and associated
auth-service with its application Security Group through
SecurityGroupPolicy. - Status: implemented and live verified.

RDS PostgreSQL - Provisioned enterprise-platform-dev-authdb for
auth-service. - Status: live and application connectivity verified.

Database Security - RDS Security Group permits PostgreSQL traffic from
the auth-service application Security Group. - Status: implemented and
live verified.

Workload Identity / IRSA - auth-service uses its platform-created
database workload identity. - Status: implemented and live verified.

Secrets Manager - RDS credentials are platform-managed in AWS Secrets
Manager. - Status: implemented and live verified through successful
database connection.

ArgoCD - auth-service and platform applications are reconciled through
ArgoCD. - Status: Synced / Healthy.

AWS Load Balancer Controller - Environment-derived VPC configuration is
used for the controller. - Status: Synced / Healthy; auth-service ALB
live.

Route53 - Root and DEV child hosted zones are separated and delegated. -
Status: implemented and live verified.

ACM - Certificate covers the DEV wildcard/base domain. - Status:
implemented and live verified through HTTPS.

ExternalDNS - Kubernetes ingress is integrated with the DEV Route53
zone. - Status: Synced / Healthy.

Auth-Service - Connected Spring Boot runtime to platform-provisioned
PostgreSQL. - Status: live, 2/2 replicas available, db=UP, HTTPS health
endpoint UP.

CI/CD - CoreDNS network fix committed as: 5500a34 Allow application pods
to access CoreDNS - Status: successfully pushed and deployed through the
infrastructure pipeline.

Explicitly Obsolete Earlier Statements

Earlier statement:

"auth-service has not yet been connected to a real PostgreSQL database."

Current replacement:

auth-service is connected to and has verified connectivity with a live platform-provisioned PostgreSQL database.

Earlier statement:

"PostgreSQL persistence is not yet implemented."

Current replacement:

PostgreSQL infrastructure and application database connectivity are implemented and verified. Application schema/migrations and real CRUD persistence remain to be implemented.

Earlier statement:

"DEV EKS was destroyed after validation."

Current replacement:

DEV EKS was previously destroyed for cost control and has since been recreated for the current development/validation window.

Earlier statement:

"The next milestone is to provision PostgreSQL for auth-service."

Current replacement:

PostgreSQL infrastructure and connectivity are complete. The next milestone is automated application schema migration and real application persistence.

61. Architecture Decision --- Application Schema Ownership

Decision:

Application schemas are application-owned.

Platform responsibility:

Provision database infrastructure and secure access.

Application responsibility:

Define and evolve schema through migrations.

Initial implementation:

Flyway for Spring Boot auth-service.

Future:

Preserve a generic migration capability so Node.js and other runtimes can use an appropriate migration implementation.

62. Architecture Decision --- Developer Interface Timing

Decision:

Do not introduce Backstage before the backend Service Contract and Golden Paths are proven.

Current:

Git/Terraform-backed Service Contract for validation.

Future:

Backstage becomes a presentation/control-plane layer over the same contract.

The UI should not contain infrastructure-specific decisions.

Architecture Decision --- Runtime vs Database

Decision:

Runtime and persistence are independent platform capabilities.

Therefore:

Spring Boot + PostgreSQL
Node.js + PostgreSQL
future Python + PostgreSQL

can consume the same database infrastructure Golden Path.

Runtime-specific behavior should remain limited to build, deployment,
runtime configuration, and migration implementation where required.

Next Session Starting Point

Do not make additional AWS networking changes unless a new test
demonstrates a networking problem.

Current starting state:

DEV EKS                         Healthy
ArgoCD applications             Synced / Healthy
auth-service                    2/2 Ready
PostgreSQL connectivity         Verified
ALB                             Working
Route53                         Working
HTTPS                           Working
Database health                 UP

Next implementation:

Formalize migration capability
    ↓
Implement Flyway for auth-service
    ↓
Create initial schema migration
    ↓
Execute automatically
    ↓
Verify tables
    ↓
Test real CRUD persistence

After that:

Generalize capability
    ↓
Node.js + PostgreSQL
    ↓
Database Access Golden Path
    ↓
Backstage

65. Final Architectural Principle

The governing architecture remains:

Developers describe intent.
Resolver interprets intent.
Policy determines what is permitted.
Provisioner executes resolved decisions.
Golden Paths implement infrastructure.
Environments provide context and policy.
Terraform manages infrastructure.
ArgoCD manages Kubernetes workloads.
Applications own schema migrations.
Backstage eventually provides the developer-facing control plane.

The platform should continue to absorb infrastructure complexity while
keeping application-specific behavior with the application.

End of current-state document --- September 17, 2026

66. Detailed Implementation and Troubleshooting Journal

This section is intentionally different from the architectural narrative
above.

The architectural sections explain what the platform is and why it
is designed that way.

This journal explains what we actually changed, what was
removed, what failed, how we investigated it, which commands
were used, what the evidence showed, and what architectural
decision followed.

The goal is that another engineer can reproduce the reasoning without
having to reconstruct it from chat history.

66.1 Documentation Rule

For every material platform change, record:

Starting state.

Problem or design pressure.

Investigation.

Commands used.

Evidence observed.

File/module changed.

Before → after.

Why the change was made.

Validation performed.

Result.

Remaining technical debt.

This is the implementation history of the platform.

67. Architecture Refactor --- Bootstrap vs Environment

Starting State

The platform initially had stronger coupling between shared Bootstrap
infrastructure and application environments.

Change

We separated:

Bootstrap
  └── platform foundation

Environment
  └── application runtime

The environment now owns its own:

VPC

public subnets

private subnets

database subnets

NAT

EKS

environment-specific networking

Bootstrap retains:

Jenkins

shared IAM

Terraform state/backend

shared foundation resources

Bootstrap VPC

Why

An environment must be disposable without destroying the platform
infrastructure that operates it.

Result

DEV can be destroyed and recreated independently.

68. Removed Bootstrap → DEV Network Coupling

Problem

Jenkins lives in the Bootstrap VPC while EKS lives in the DEV VPC.

An earlier approach attempted to create a security-group rule that
directly referenced the Jenkins security group from the DEV EKS security
group.

AWS rejected the relationship because the security groups belong to
different VPCs.

Evidence

The failure was reported as an AWS InvalidGroup.NotFound-type error
indicating the groups were not in the same network.

Root Cause

Security groups are VPC-scoped.

Bootstrap VPC
  └── Jenkins SG

DEV VPC
  └── EKS SG

They cannot be directly referenced as though they were in one VPC.

Change

Removed the invalid Jenkins → EKS security-group rule.

Removed the need for Bootstrap/DEV VPC peering for this purpose.

Replacement

Use the EKS API endpoint:

cluster_endpoint_public_access       = true
cluster_endpoint_private_access      = true
cluster_endpoint_public_access_cidrs = var.allowed_k8s_api_cidrs

Jenkins reaches the EKS public API over HTTPS 443 when its public IP is
allow-listed.

Validation

The EKS API became reachable without creating permanent network coupling
between Bootstrap and DEV.

Architectural Lesson

Do not weaken environment isolation to solve an administrative access
problem when the platform already has a controlled API access mechanism.

69. Generalized Networking Module

Problem

Kubernetes-specific subnet tags had been too tightly coupled to generic
networking.

Change

The networking module was changed to accept:

variable "enable_kubernetes_tags" {
  type    = bool
  default = false
}

variable "cluster_name" {
  type    = string
  default = null
}

When enabled, Kubernetes subnet tags are applied.

Before

Generic networking implicitly carried Kubernetes assumptions.

After

Generic networking module
        +
optional Kubernetes behavior

Bootstrap does not enable the Kubernetes tags.

DEV does.

Why

The module remains reusable for non-Kubernetes environments.

70. EKS Addon Ordering

Problem

Worker nodes depend on functional cluster networking.

Change

The VPC CNI addon was deliberately ordered before compute:

vpc-cni
   ↓
worker compute

using the EKS module's before_compute = true behavior.

Why

Nodes should not be created before the networking layer they depend on
is ready.

Result

The EKS Golden Path explicitly expresses the dependency rather than
relying on accidental ordering.

71. EKS Authentication Troubleshooting

Symptom

kubectl initially returned credential/authentication errors.

Investigation

The local AWS authentication context was not using the expected
deployment role.

The AWS identity was corrected and STS identity was verified.

Validation Commands

aws sts get-caller-identity

Then:

aws eks update-kubeconfig \
  --region us-east-1 \
  --name enterprise-platform-dev

And:

kubectl get nodes

Result

The workstation authenticated to EKS successfully.

Architectural Note

EKS access is granted through explicit EKS access entries rather than
relying on whichever identity happened to create the cluster.

72. EKS Node Group Failure

Symptom

The first live apply encountered a managed node-group failure:

CREATE_FAILED
NodeCreationFailure

Unhealthy nodes were reported.

At the same time, a Jenkins-to-EKS security-group resource failed.

Investigation Principle

The two failures were treated as separate problems.

The node bootstrap problem was not automatically attributed to the
security-group-rule failure.

Recovery

The node group was subsequently recovered and stabilized.

Workers eventually reported:

Ready

and required system workloads became operational.

Lesson

When Terraform creates several dependent resources, separate independent
failure domains before changing architecture.

73. AWS Load Balancer Controller --- VPC ID Problem

Problem

The AWS Load Balancer Controller initially contained an
incorrect/hard-coded DEV VPC ID.

This caused subnet discovery problems.

Investigation

The actual DEV VPC was verified from Terraform/AWS.

Current DEV VPC:

vpc-0fcffdfde6eeb1bc

Change

The Jenkins infrastructure pipeline was changed to obtain the VPC ID
from Terraform:

env.VPC_ID = sh(
    script: "terraform output -raw vpc_id",
    returnStdout: true
).trim()

Then Jenkins updates GitOps:

yq e -i '
  .serviceAccount.annotations."eks.amazonaws.com/role-arn" = env(ALB_ROLE) |
  .vpcId = env(VPC_ID)
' charts/aws-load-balancer-controller/values.yaml

Before

vpcId: <hard-coded DEV VPC>

After

vpcId: <Terraform-derived VPC>

Validation

The controller successfully reconciled ingress resources and created
ALBs.

The controller logs showed the expected DEV VPC being used.

Remaining Work

The VPC ID should eventually be derived through a cleaner
environment-aware GitOps mechanism rather than being written into GitOps
as an infrastructure artifact.

74. ALB Controller GitOps Cleanup

Change

The old root-level ALB application definition was removed:

alb-app.yaml

The canonical ArgoCD application became:

applications/aws-load-balancer-controller.yaml

The controller values are maintained in:

charts/aws-load-balancer-controller/values.yaml

Current Important Values

clusterName: enterprise-platform-dev
region: us-east-1

serviceAccount:
  create: true
  name: aws-load-balancer-controller

The IAM role annotation is injected/updated by the platform pipeline.

Result

There is one canonical GitOps definition instead of parallel/stale
definitions.

75. Route53 DNS Architecture

Starting State

The domain was registered with Namecheap.

The platform needed environment-specific DNS without creating the root
DNS architecture repeatedly.

Change

Bootstrap became responsible for:

dreammyles.online
        ↓
dev.dreammyles.online

The DEV child zone is delegated from the Bootstrap root zone.

Bootstrap

module "route53_root" {
  source = "../../modules/route53"

  project      = "enterprise-platform"
  environment  = "bootstrap"
  domain_name  = var.domain_name
}

module "route53_dev" {
  source = "../../modules/route53"

  project      = "enterprise-platform"
  environment  = "dev-dns"
  domain_name  = var.dev_domain_name
}

resource "aws_route53_record" "dev_delegation" {
  zone_id = module.route53_root.hosted_zone_id
  name    = var.dev_domain_name
  type    = "NS"
  ttl     = 300
  records = module.route53_dev.hosted_zone_name_servers
}

Result

Namecheap delegates the root domain to Route53.

Route53 then delegates:

dev.dreammyles.online

to its child hosted zone.

Why

DNS ownership follows lifecycle ownership.

Bootstrap owns the stable DNS foundation.

DEV consumes the delegated zone.

76. ACM Certificate Correction

Problem

The certificate naming logic had introduced an incorrect extra dev.
component.

Before

The generated domain could effectively become:

*.dev.dev.dreammyles.online

Change

The certificate module was corrected to derive from the environment's
actual domain:

resource "aws_acm_certificate" "platform" {
  domain_name = "*.${var.domain_name}"

  subject_alternative_names = [
    var.domain_name
  ]
}

Result

DEV certificate covers:

*.dev.dreammyles.online
dev.dreammyles.online

Therefore:

api.dev.dreammyles.online

is covered.

77. Jenkins → GitOps Dynamic Configuration

Problem

Infrastructure-generated values such as IAM role ARNs, certificate ARNs,
VPC IDs, and hostnames cannot safely be maintained as stale hard-coded
values in GitOps.

Change

Jenkins reads Terraform outputs and updates GitOps using yq.

Examples:

yq e -i '
  .serviceAccount.annotations."eks.amazonaws.com/role-arn" = env(EXTERNAL_DNS_ROLE)
' charts/external-dns/values.yaml

yq e -i '
  .serviceAccount.annotations."eks.amazonaws.com/role-arn" = env(ALB_ROLE)
' charts/aws-load-balancer-controller/values.yaml

yq e -i '
  .alb.certificateArn = env(CERTIFICATE_ARN)
' charts/networking/values.yaml

yq e -i '
  .server.ingress.annotations."alb.ingress.kubernetes.io/certificate-arn" = env(CERTIFICATE_ARN)
' charts/argocd/values.yaml

Validation

The pipeline checks for stale certificate references:

WRONG=$(git grep "certificate-arn" | grep -v "$CERTIFICATE_ARN" || true)

if [ -n "$WRONG" ]; then
    echo "ERROR: Found outdated certificate references"
    echo "$WRONG"
    exit 1
fi

Result

GitOps values are updated from the current infrastructure outputs rather
than manually copied.

78. Application Security Group --- Empty Rules Problem

Symptom

The application Security Group existed:

sg-092eb850b231b34be

but had no useful ingress/egress rules.

The RDS Security Group allowed inbound PostgreSQL from the application
SG, but the application SG itself had no outbound path.

Impact

The application experienced failures such as:

UnknownHostException

and database connection timeouts.

Root Cause

The security relationship was only half-built:

Application SG
    X
    ↓
RDS SG

The RDS SG trusted the application SG, but the application SG had no
egress.

Change

Added an explicit application SG egress model.

79. Application Security Group --- DNS Egress

Added Variable

variable "vpc_cidr" {
  description = "CIDR block of the VPC where the application runs"
  type        = string
}

Added Rules

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.this.id

  description = "Allow DNS queries to the VPC resolver"

  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.this.id

  description = "Allow DNS TCP queries to the VPC resolver"

  ip_protocol = "tcp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = var.vpc_cidr
}

Why Both TCP and UDP

DNS normally uses UDP, but TCP is also required for DNS operations in
some cases and was specifically relevant to the troubleshooting path.

80. Application Security Group --- HTTPS Egress

Added Rule

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id

  description = "Allow HTTPS access to AWS services and external endpoints"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

Why

The application/workload needs HTTPS access to AWS services and external
endpoints used by the platform.

This was deliberately separated from database access.

81. Application Security Group --- Database Egress

Added at Provisioning Composition Layer

The provisioning layer creates the cross-resource relationship:

resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  for_each = local.database_creation_requests

  security_group_id =
    module.application_security_group[each.key].security_group_id

  description =
    "Allow ${each.key} to access its platform-managed database"

  ip_protocol = "tcp"

  from_port = module.database[each.key].database_port
  to_port   = module.database[each.key].database_port

  referenced_security_group_id =
    module.database[each.key].security_group_id
}

Why This Location

The application SG module should not know about every database.

The provisioning composition layer knows that:

service
   ↓
application SG
   ↓
database

Therefore the cross-cutting relationship belongs there.

82. Why We Did Not Modify the EKS Module

Considered Approach

Pass application Security Group IDs into the EKS module and make EKS own
the DNS ingress rule.

Rejected

This would create a backwards dependency:

EKS foundation
      ↑
application provisioning

The EKS module is foundational.

The application SG is created by platform provisioning.

Final Approach

The environment composition layer owns the cross-cutting rule:

environments/dev/main.tf

This is where both:

EKS node SG

application SG

are available.

83. SG-for-Pods Implementation

Goal

Use AWS Security Groups for Pods instead of opening RDS access from the
entire worker-node Security Group.

Existing Prerequisites

VPC CNI was configured with:

ENABLE_POD_ENI = true
POD_SECURITY_GROUP_ENFORCING_MODE = standard

The required EKS VPC Resource Controller permissions and CRDs were
present.

Application SG

sg-092eb850b231b34be

RDS SG

sg-070e1746bace53b7b

Intended Network Path

auth-service Pod
      ↓
auth-service Application SG
      ↓
RDS Security Group
      ↓
PostgreSQL :5432

The node SG does not become the database authorization boundary.

84. SecurityGroupPolicy GitOps Implementation

Change

Added:

charts/auth-service/templates/security-group-policy.yaml

The template creates:

apiVersion: vpcresources.k8s.aws/v1beta1
kind: SecurityGroupPolicy

with:

podSelector:
  matchLabels:
    app.kubernetes.io/name: auth-service
    app.kubernetes.io/instance: auth-service

and:

securityGroups:
  groupIds:
    - "<platform-resolved-application-SG>"

Why

The developer should not provide raw AWS SG IDs.

The platform resolves:

service
  ↓
application SG
  ↓
GitOps SecurityGroupPolicy

Validation

Helm rendering produced:

groupIds:
  - "sg-092eb850b231b34be"

and the deployment labels matched the selector.

85. Jenkins Application Security Group Resolution

Problem

Jenkins was reading the Terraform application security-group output but
silently falling back to {} when the output was unavailable.

Before

env.APPLICATION_SECURITY_GROUPS = sh(
    script: "terraform output -json application_security_groups 2>/dev/null || echo '{}'",
    returnStdout: true
).trim()

Problem With This

A missing Terraform output became:

{}

and the pipeline could continue without exposing the real problem.

After

env.APPLICATION_SECURITY_GROUPS = sh(
    script: "terraform output -json application_security_groups",
    returnStdout: true
).trim()

The pipeline now fails visibly if the output cannot be read.

Explicit Validation

if [ -z "$APPLICATION_SECURITY_GROUPS" ] ||
   [ "$APPLICATION_SECURITY_GROUPS" = "{}" ]; then

    echo "ERROR: APPLICATION_SECURITY_GROUPS is empty."
    echo "Terraform did not provide the application security group output."
    exit 1
fi

Service Resolution

export AUTH_SERVICE_APPLICATION_SG=$(
  echo "$APPLICATION_SECURITY_GROUPS" |
  jq -r '."auth-service".id // empty'
)

Result

Jenkins resolved:

Auth Service Application Security Group:
sg-092eb850b231b34be

and wrote it to:

charts/auth-service/values-dev.yaml

86. CoreDNS Troubleshooting --- First Test

Symptom

The application still experienced DNS/database connection problems even
after application SG egress was added.

Diagnostic Pod

A temporary BusyBox pod was created:

kubectl run network-test \
  -n identity \
  --image=busybox:1.36 \
  --restart=Never \
  --labels='app.kubernetes.io/name=auth-service,app.kubernetes.io/instance=auth-service' \
  --command -- sleep 3600

Why These Labels

The labels intentionally matched the auth-service SecurityGroupPolicy.

This allowed the diagnostic pod to receive the same application SG as
auth-service.

87. CoreDNS --- VPC Resolver Test

The diagnostic pod tested the VPC resolver directly:

nc -vz 10.10.0.2 53

and:

nc -vzu -w 5 10.10.0.2 53

The resolver was reachable.

Then:

nslookup \
  enterprise-platform-dev-authdb.c5wqkyiq8ame.us-east-1.rds.amazonaws.com \
  10.10.0.2

returned the RDS private address:

10.10.22.207

Conclusion

VPC DNS itself was functioning.

The failure was farther along the Kubernetes DNS path.

88. CoreDNS --- Kubernetes DNS Test

The Kubernetes DNS service was:

kube-dns
ClusterIP: 172.20.0.10

CoreDNS pods were:

10.10.11.27
10.10.12.233

The EndpointSlice correctly selected:

kubernetes.io/service-name=kube-dns

Test

Direct DNS queries to:

172.20.0.10
10.10.11.27
10.10.12.233

timed out.

This demonstrated that the problem was not the existence of CoreDNS or
its service/endpoints.

89. CoreDNS --- Node Security Group Discovery

Both CoreDNS nodes used:

sg-0e6a963d6bc0fd76b

The node SG had DNS rules for node-to-node traffic, but the diagnostic
pod using the application SG could not reach TCP/53 on the CoreDNS
nodes.

Direct Test

nc -vz 10.10.11.191 53

timed out.

UDP:

nc -vzu -w 5 10.10.11.191 53

was open.

The same pattern occurred against:

10.10.12.224

Important Evidence

Pod → VPC resolver : works
Pod → CoreDNS node TCP/53 : fails
Pod → CoreDNS node UDP/53 : works

This isolated the missing rule to the node security-group path.

90. CoreDNS --- Final Security Group Fix

Change Location

We deliberately did not modify the foundational EKS module.

The fix was added to:

environments/dev/main.tf

Added TCP Rule

resource "aws_vpc_security_group_ingress_rule" "node_from_application_dns_tcp" {
  for_each = var.enable_eks
    ? module.provisioning.application_security_groups
    : {}

  security_group_id =
    module.eks[0].node_group_security_group_id

  referenced_security_group_id = each.value.id

  ip_protocol = "tcp"
  from_port   = 53
  to_port     = 53

  description =
    "Allow ${each.key} application pods to access CoreDNS over TCP"
}

Added UDP Rule

resource "aws_vpc_security_group_ingress_rule" "node_from_application_dns_udp" {
  for_each = var.enable_eks
    ? module.provisioning.application_security_groups
    : {}

  security_group_id =
    module.eks[0].node_group_security_group_id

  referenced_security_group_id = each.value.id

  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53

  description =
    "Allow ${each.key} application pods to access CoreDNS over UDP"
}

Terraform Plan

The plan showed:

2 to add
0 to change
0 to destroy

Specifically:

auth-service application SG
        ↓
EKS node SG
        ↓
CoreDNS

for TCP/53 and UDP/53.

Deployment Rule

Because Jenkins is the intended infrastructure deployment path:

commit
  ↓
push
  ↓
Jenkins
  ↓
Terraform plan/apply

The change should not be applied manually from the workstation once
committed to the pipeline-controlled workflow.

91. Terraform Formatting Failure

Symptom

A Jenkins infrastructure run failed because the Terraform change was not
formatted according to repository expectations.

Investigation

Terraform formatting was run locally.

Change

Formatting was corrected and committed.

The follow-up commit was:

51328df
Format provisioning variables

Lesson

Infrastructure code should pass local:

terraform fmt
terraform validate
terraform plan

before the pipeline is used for deployment.

92. GitOps Auth-Service Security Group Change History

The application SecurityGroupPolicy work progressed through Git commits
including:

b37e660  Add auth service pod security group policy

Remote Jenkins-generated GitOps changes included:

08d04ae
6b9b36e

A merge reconciled the security-group policy work:

2f19b19
Merge remote GitOps updates with security group policy

Later infrastructure-output synchronization commits included:

446c511
90f2395

These commits represent the transition from manually maintained
application SG configuration toward Terraform-derived platform values
being written into GitOps.

93. Database Golden Path Implementation

Goal

Allow a service contract to request a managed PostgreSQL database
without exposing raw AWS implementation details to the developer.

Resolver Input

The persistence contract supports:

none
new
existing
shared
temporary

with logical values such as:

engine = postgres
size   = small
access = read / read_write

Resolver Responsibility

The Resolver validates the contract and produces a normalized action.

For a new database:

action = create

For existing/shared access:

action = access

Provisioner Responsibility

The Provisioner receives:

environment_context

and resolved requests.

It does not receive Bootstrap internals.

Database Provisioning

The provisioning layer invokes:

module "database" {
  for_each = local.database_creation_requests

  source = "../../modules/database"

  project     = var.project
  environment = var.environment

  vpc_id = var.environment_context.vpc_id

  private_subnet_ids =
    var.environment_context.database_subnet_ids

  database_name = each.value.database_name
  engine        = each.value.engine
  size          = each.value.size
  application_name = each.key
  owner_team       = each.value.team

  application_security_group_id =
    module.application_security_group[each.key].security_group_id
}

Result

The live DEV database was:

enterprise-platform-dev-authdb

with:

engine = PostgreSQL
database = authdb
port = 5432

94. Database Registry Wiring

Purpose

The registry translates physical AWS resources into platform-level
logical information.

Recorded Information

Examples include:

logical database name
engine
environment
owner team
resource identifier
endpoint
port
credential reference
status

Why

A future service should request:

database = authdb

rather than:

RDS identifier = enterprise-platform-dev-authdb

This keeps AWS implementation details inside the platform.

95. Secrets Manager and Workload Identity

Secret Principle

Credentials are not stored in application Git repositories.

The platform records a credential reference such as:

AWS Secrets Manager

rather than a static password.

Workload Identity

The auth-service receives a platform-created workload identity:

enterprise-platform-dev-auth-service-database

The workload accesses AWS through EKS workload identity/IRSA.

Result

The application image and Git repository do not contain AWS credentials.

96. External Secrets Troubleshooting

Symptom

Some workloads entered:

CreateContainerConfigError

because Kubernetes Secrets had not been created.

ExternalSecret objects reported:

SecretSyncedError

Investigation

The following were verified:

External Secrets Operator was running.

ClusterSecretStore was operational.

AWS Secrets Manager objects existed.

The missing piece was that the Secrets Manager objects did not have a
usable AWSCURRENT secret version.

Lesson

This distinction is important:

Secret object exists
        ≠
Usable current secret version exists

Fix Direction

Recover/create the usable current secret version while keeping secret
values outside Git.

97. Auth-Service AWS SDK Startup Failure

Symptom

The application could not initialize the AWS-backed secret access path.

Change

The AWS STS dependency was added to support web-identity-based
credentials.

The application was configured to use the AWS default credential
provider chain and the platform-provided credential reference.

Principle

The application should obtain AWS credentials from workload identity
rather than static access keys.

98. Jenkins Pipeline Structure

The application pipeline evolved into:

Checkout
  ↓
Build & Unit Tests
  ↓
SonarQube Analysis
  ↓
Quality Gate
  ↓
OWASP Dependency Check
  ↓
Trivy Filesystem Scan
  ↓
Docker Build
  ↓
Trivy Container Scan
  ↓
ECR Login
  ↓
Push Image
  ↓
Update GitOps
  ↓
ArgoCD

The OWASP stage was made optionally executable through:

booleanParam(
    name: 'RUN_OWASP_SCAN',
    defaultValue: false,
    description: 'Run OWASP Dependency Check scan'
)

This was used to avoid forcing the expensive dependency scan into every
development build while retaining the capability.

99. Jenkins Pipeline Troubleshooting History

Jenkinsfile Parsing Failure

Error

unexpected char: '`'

Cause

Markdown code fences had been copied into the Jenkinsfile.

Change

Removed Markdown fences and retained only Groovy syntax.

Missing Closing Braces

Error

expecting '}'

Cause

Nested stage, steps, and post blocks were incorrectly closed.

Change

The Groovy nesting was reviewed and corrected.

Maven Build Failure

Error

The goal you specified requires a project to execute but there is no POM in this directory

Cause

The repository is a monorepo.

The Maven project is under:

services/auth-service

Change

Added:

SERVICE_DIR = "services/auth-service"

and ran Maven inside:

dir("${SERVICE_DIR}") {
    sh 'mvn clean verify'
}

Missing JUnit Reports

Error

No test report files were found

Cause

The test directory existed but contained no test classes.

Change

A Spring Boot test was added:

src/test/java/com/platform/auth/AuthApplicationTests.java

This allowed Maven/Surefire to produce test results.

100. DEV Runtime Shutdown

Reason

EKS and NAT are expensive runtime resources.

After live validation, the environment was intentionally shut down.

Configuration

enable_eks         = false
enable_nat_gateway = false

Result

Terraform destroyed the expensive runtime resources while retaining the
DEV VPC/subnet foundation.

The recorded destroy completed with:

55 resources destroyed

Retained

DEV VPC
public subnets
private subnets
database subnets

Destroyed

EKS
managed node group
EKS addons
runtime IAM/OIDC resources
EKS runtime security groups
NAT Gateway
NAT EIP

101. Post-EKS Cleanup

Important Observation

Destroying EKS did not guarantee that every AWS resource created by
Kubernetes controllers disappeared.

Two Kubernetes-created ALBs remained.

Action

The ALBs were manually deleted after confirming the EKS runtime was
gone.

Lesson

Always verify controller-created AWS resources after cluster
destruction.

102. Dynamic PVC EBS Cleanup

An EBS inventory identified four unattached volumes with names matching:

enterprise-platform-dev-dynamic-pvc-*

These belonged to disposable DEV Kubernetes storage.

They were removed.

A subsequent query for available EBS volumes returned no results.

Important Boundary

These volumes were not confused with the persistent Jenkins EBS volumes
in Bootstrap.

103. Jenkins EBS and ENI Retention

Two 30 GiB EBS volumes remain associated with the stopped Jenkins EC2
instance.

One is explicitly named:

jenkins-data-volume

The other has no Name tag.

They remain because Jenkins is part of the persistent Bootstrap
foundation.

The Jenkins ENI also remains in use by the stopped Jenkins instance.

It is not an orphaned DEV EKS interface.

104. Resource Verification Commands

EKS

aws eks list-clusters --region us-east-1

Expected after DEV shutdown:

no DEV clusters

NAT

aws ec2 describe-nat-gateways \
  --region us-east-1 \
  --filter Name=state,Values=available,pending

Available EBS

aws ec2 describe-volumes \
  --region us-east-1 \
  --filters Name=status,Values=available \
  --output table

Full EBS Inventory

aws ec2 describe-volumes \
  --region us-east-1 \
  --query 'Volumes[].{
    ID:VolumeId,
    State:State,
    Size:Size,
    Created:CreateTime,
    Name:Tags[?Key==`Name`]|[0].Value,
    AttachedTo:Attachments[0].InstanceId
  }' \
  --output json

Kubernetes

kubectl get nodes

kubectl get applications -n argocd

Helm

helm lint <chart-path>

helm template <chart-path>

105. Terraform Validation Workflow

For infrastructure changes, the intended local validation sequence is:

terraform fmt
terraform validate
terraform plan

The workstation is used to validate the proposed change.

The Jenkins pipeline remains the deployment path.

This creates:

Local validation
      ↓
Git commit
      ↓
Git push
      ↓
Jenkins
      ↓
Terraform deployment

106. Current Live DEV Resource Snapshot

When DEV runtime was active, the following resources were validated.

Network

VPC:
vpc-0fcffdfde6eeb1bc

CIDR:
10.10.0.0/16

Application Security Group

auth-service:
sg-092eb850b231b34be

RDS Security Group

sg-070e1746bace53b7b

Node Security Group

sg-0e6a963d6bc0fd76b

PostgreSQL

enterprise-platform-dev-authdb

Endpoint:

enterprise-platform-dev-authdb.c5wqkyiq8ame.us-east-1.rds.amazonaws.com

Database:

authdb

Port:

5432

EKS

enterprise-platform-dev

Auth Namespace

identity

Auth Service

auth-service:8080

107. Live End-to-End Validation Evidence

The platform eventually validated the following runtime path:

Internet
   ↓
Route53
   ↓
api.dev.dreammyles.online
   ↓
AWS ALB
   ↓
Kubernetes Service
   ↓
auth-service Pod
   ↓
Application Security Group
   ↓
DNS / CoreDNS
   ↓
RDS Security Group
   ↓
PostgreSQL
   ↓
Spring Boot datasource

The application health endpoint reported:

status = UP
db = UP
database = PostgreSQL
livenessState = UP
readinessState = UP

An undefined route returning HTTP 404 was also treated as useful
infrastructure evidence because it demonstrated that the request reached
Spring Boot.

108. What Was Removed During the Refactor

The following implementation patterns were deliberately removed or
rejected:

Direct Bootstrap → DEV VPC security-group references.

VPC peering as the default Jenkins → EKS connectivity mechanism.

Hard-coded VPC IDs as permanent GitOps configuration.

Generic networking modules carrying mandatory Kubernetes
assumptions.

Application SG → RDS access through the broad worker-node SG.

Silent {} fallback when Terraform application-SG output was
unavailable.

Raw AWS implementation identifiers in the developer-facing service
contract.

Manual SecurityGroupPolicy ownership outside GitOps.

Static application credentials in Git.

Treating Bootstrap networking as the lifecycle dependency of DEV.

109. What Was Added

The implementation added or strengthened:

Environment-owned networking.

Environment context.

Resolver normalization.

Provisioner orchestration.

Application Security Groups.

Application SG DNS/HTTPS/database egress.

AWS Security Groups for Pods.

GitOps SecurityGroupPolicy.

Terraform-derived application SG resolution.

CoreDNS node-SG ingress for application pods.

Database Golden Path.

Database registry.

Secrets Manager integration.

Workload identity.

Route53 root/child-zone delegation.

ACM wildcard certificate handling.

Terraform-output-driven GitOps updates.

Controlled DEV shutdown.

Post-destroy AWS resource verification.

Detailed validation and troubleshooting workflow.

110. Documentation Cross-Reference

The master document is the complete source of truth.

The modular documents in this repository are focused extracts intended
to live close to the code they describe.

Recommended layout:

docs/
├── README.md
├── MASTER.md
├── architecture/
│   ├── architecture-decisions.md
│   ├── environment-lifecycle.md
│   └── change-history.md
├── resolver/
│   └── resolver.md
├── provisioning/
│   └── provisioning.md
├── environments/
│   └── dev.md
├── networking/
│   └── networking-and-sg-pods.md
├── eks/
│   └── eks.md
├── database/
│   └── database.md
├── secrets/
│   └── secrets-and-workload-identity.md
├── gitops/
│   └── gitops.md
├── jenkins/
│   └── jenkins.md
├── dns/
│   └── route53-acm-externaldns.md
├── argocd/
│   └── argocd.md
└── troubleshooting/
    └── troubleshooting.md

The modular documents should not become independent competing sources of
truth. They should summarize the relevant implementation area and point
back to the master document.

111. Current Documentation Principle

The documentation is intentionally maintained at two levels:

Level 1 --- Master

The master explains:

architecture

rationale

implementation

changes

removals

troubleshooting

commands

evidence

decisions

lifecycle

current state

next steps

Level 2 --- Module Documentation

Each module document explains only the part of the implementation
relevant to that directory/component.

Example:

resolver/resolver.md

contains Resolver-specific changes.

provisioning/provisioning.md

contains Provisioner-specific changes.

environments/dev.md

contains DEV composition and lifecycle changes.

The master remains the authoritative historical record.

112. Documentation Maintenance Rule Going Forward

Every time we make a significant change, the same change should be
recorded in:

The master document.

The appropriate component-specific document.

The change history when the change alters architecture or lifecycle.

The troubleshooting document if the change resulted from a failure
investigation.

Each entry should use:

Problem
↓
Investigation
↓
Evidence / command
↓
Before
↓
Change
↓
After
↓
Validation
↓
Architectural reason
↓
Remaining debt

This prevents the platform documentation from becoming a collection of
final-state descriptions with no explanation of how the final state was
reached.

113. Final Documentation Principle

The platform documentation should preserve not only the final
architecture but also the engineering path used to reach it.

A future engineer should be able to answer:

What was wrong?

How did we know it was wrong?

Which command proved it?

What file did we change?

What did the code look like before?

What did it become?

Why was that design chosen?

What did we deliberately remove?

How did we validate the change?

What remains unfinished?

That implementation history is part of the platform itself.