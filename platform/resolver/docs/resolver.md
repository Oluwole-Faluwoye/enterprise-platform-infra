Resolver

Responsibility

The Resolver interprets developer intent and produces normalized
platform actions.

It does not create AWS resources.

Developer persistence modes

none
new
existing
shared
temporary

Validation rules

Examples:

enabled=false must not request database creation.

new requires engine and size.

existing/shared require a logical database name and access level.

Access is read or read_write.

Engines include PostgreSQL and other supported logical engines.

Namespace

The developer supplies:

team: identity

The Resolver derives:

namespace = identity

The developer does not supply the Kubernetes namespace directly.

Action model

A new database request resolves to:

action=create

Existing/shared database access resolves to:

action=access

This prevents a service that needs access from accidentally creating a
duplicate database.

Boundary

Service Contract
      ↓
Resolver
      ↓
Resolved Action
      ↓
Provisioner

The Provisioner consumes the resolved result; it does not reinterpret
developer intent.