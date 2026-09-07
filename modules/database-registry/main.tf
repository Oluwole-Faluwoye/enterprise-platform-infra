# =========================================================
# DATABASE REGISTRY GOLDEN PATH
# =========================================================
#
# The Database Registry provides the authoritative logical
# mapping between platform database names and their physical
# infrastructure metadata.
#
# This module does not create databases.
#
# It normalizes:
#
#   - databases already registered with the platform
#   - databases created during the current provisioning run
#
# Persistence will be introduced separately.
# =========================================================

terraform {

  required_version = ">= 1.6.0"

}
