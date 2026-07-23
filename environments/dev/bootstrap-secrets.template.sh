#!/bin/bash

set -e

echo "Bootstrapping AWS Secrets Manager..."

aws secretsmanager put-secret-value \
  --secret-id enterprise-platform/dev/auth-service \
  --secret-string '{
    "jwt-secret":"CHANGE_ME",
    "database-url":"jdbc:postgresql://postgres:5432/authdb",
    "database-username":"postgres",
    "database-password":"CHANGE_ME"
}'

aws secretsmanager put-secret-value \
  --secret-id enterprise-platform/dev/grafana/admin \
  --secret-string '{
    "admin-user":"admin",
    "admin-password":"CHANGE_ME"
}'

aws secretsmanager put-secret-value \
  --secret-id enterprise-platform/dev/alertmanager \
  --secret-string '{
    "smtp-host":"smtp.example.com",
    "smtp-port":"587",
    "smtp-username":"CHANGE_ME",
    "smtp-password":"CHANGE_ME"
}'

echo "Secrets bootstrapped successfully."