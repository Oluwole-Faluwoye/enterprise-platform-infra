Database Golden Path

Purpose

Provision platform-managed PostgreSQL through the Service Contract →
Resolver → Provisioner path.

Live DEV database

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

Flow

Service Contract
      ↓
Resolver
      ↓
action=create
      ↓
Provisioner
      ↓
Application SG + Database Golden Path
      ↓
RDS
      ↓
Registry
      ↓
Secrets Manager
      ↓
Workload

Security

Network access is controlled by security groups.

Credentials are handled through Secrets Manager.

AWS access is provided through workload identity.

Future

Existing/shared access uses action=access and will be implemented as
the Database Access Golden Path.