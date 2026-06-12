# Trivy

## Overview

Trivy is a container and vulnerability scanner used to identify security risks in container images and application dependencies.

It is integrated into the CI pipeline after image creation.

---

# Purpose

Detect:

* Critical vulnerabilities
* High vulnerabilities
* Outdated packages
* Misconfigurations
* Secrets accidentally committed

before deployment.

---

# CI/CD Flow

GitHub
↓
Jenkins
↓
Docker Build
↓
Trivy Scan
↓
ECR Push

---

# Why Trivy Matters

Without image scanning:

* Vulnerable packages enter production
* Known CVEs remain exploitable

Trivy provides early vulnerability detection.

---

# Example Command

```bash
trivy image auth-service:v1
```

---

# Severity Levels

* Critical
* High
* Medium
* Low

Most enterprises fail builds on:

* Critical
* High

---

# Common Issues

* Large image scan times
* Vulnerability database updates
* False positives

---

# Interview Questions

Q: What is Trivy?

A:

An open-source vulnerability scanner used to scan container images, filesystems, repositories, and Kubernetes clusters.

Q: Why scan container images?

A:

To detect vulnerabilities before deployment and reduce security risk.

---

# Concepts Learned

* Vulnerability Scanning
* Container Security
* CVEs
* Image Scanning
* DevSecOps
* Security Automation
