#!/bin/bash

set -e

echo "======================================================"
echo "Bootstrapping AWS Secrets Manager"
echo "======================================================"

PROJECT="enterprise-platform"
ENVIRONMENT="dev"

############################################
# Auth Service
############################################

aws secretsmanager put-secret-value \
  --secret-id ${PROJECT}/${ENVIRONMENT}/auth-service \
  --secret-string '{
    "jwt-secret":"CHANGE_ME",
    "database-url":"jdbc:postgresql://postgres:5432/authdb",
    "database-username":"postgres",
    "database-password":"CHANGE_ME"
}'

############################################
# Grafana
############################################

aws secretsmanager put-secret-value \
  --secret-id ${PROJECT}/${ENVIRONMENT}/grafana/admin \
  --secret-string '{
    "admin-user":"admin",
    "admin-password":"CHANGE_ME"
}'

############################################
# Alertmanager
############################################

aws secretsmanager put-secret-value \
  --secret-id ${PROJECT}/${ENVIRONMENT}/alertmanager \
  --secret-string '{
    "smtp-host":"smtp.example.com",
    "smtp-port":"587",
    "smtp-username":"CHANGE_ME",
    "smtp-password":"CHANGE_ME",
    "smtp-from":"alerts@example.com",
    "smtp-to":"platform@example.com"
}'

echo
echo "✓ AWS Secrets bootstrapped successfully."