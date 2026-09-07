# =========================================================
# PLATFORM RESOLVER
# =========================================================
#
# The resolver translates developer intent into platform
# requirements.
#
# IMPORTANT:
#
# This module does NOT create AWS infrastructure.
#
# It does NOT receive or manage:
#
#   - VPC IDs
#   - subnet IDs
#   - security-group IDs
#   - RDS IDs
#   - IAM role ARNs
#   - EKS cluster IDs
#
# Those belong to the platform provisioning layer.
#
# Developer-facing contract:
#
#   runtime
#   team
#   persistence
#   database engine
#   database size
#   database access
#
# Resolver responsibilities:
#
#   1. Validate developer intent
#   2. Classify persistence requests
#   3. Determine whether infrastructure is required
#   4. Determine whether approval is required
#   5. Produce a normalized platform contract
#
# Provisioning is handled separately.
# =========================================================


# =========================================================
# RESOLVED SERVICE CONTRACT
# =========================================================
#
# local.resolved_services contains the normalized platform
# representation of every submitted service.
#
# Example:
#
# payment-service
#   runtime = java
#   environment = dev
#   persistence:
#     action = create
#     engine = postgres
#     size = medium
#
# reporting-service
#   persistence:
#     action = access
#     database = customer
#     access = read
#
# customer-api
#   persistence:
#     action = access
#     database = customer
#     access = read_write
#     approval_required = true
#
# The provisioning layer will consume this information.
# =========================================================


# =========================================================
# DATABASE REQUEST CLASSIFICATION
# =========================================================
#
# These locals are calculated in locals.tf.
#
# The resolver distinguishes:
#
#   new
#   temporary
#   existing
#   shared
#   none
#
# This allows us to avoid automatically creating a new
# database every time a developer asks for persistence.
# =========================================================


# =========================================================
# PLATFORM DECISION MODEL
# =========================================================
#
# The resolver intentionally produces decisions rather than
# AWS implementation details.
#
# For example:
#
# Developer:
#
#   engine = postgres
#   size   = medium
#
# Resolver:
#
#   action = create
#   engine = postgres
#   size   = medium
#
# Provisioner:
#
#   AWS RDS PostgreSQL
#   db.t4g.medium
#
# The developer never needs to know the AWS implementation.
# =========================================================