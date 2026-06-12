# SonarQube

## Overview

SonarQube is a static application security testing (SAST) and code quality platform used to analyze source code before deployment.

In this platform, SonarQube is integrated into Jenkins and executes after the Maven build stage.

---

# Purpose

SonarQube helps identify:

* Bugs
* Security vulnerabilities
* Code smells
* Duplicated code
* Maintainability issues

before software reaches production.

---

# CI/CD Flow

Developer
↓
GitHub Push
↓
Jenkins Build
↓
SonarQube Analysis
↓
Quality Gate Validation

---

# Why SonarQube Matters

Without code analysis:

* Poor coding practices enter production
* Security issues remain undetected
* Technical debt accumulates

SonarQube shifts quality checks left.

---

# Quality Gates

A Quality Gate is a set of conditions that code must satisfy.

Examples:

* No critical vulnerabilities
* Minimum code coverage
* No blocker issues

If a Quality Gate fails:

Pipeline fails.

---

# Jenkins Integration

Example:

```bash
mvn sonar:sonar
```

Jenkins sends analysis results to SonarQube Server.

---

# Common Issues

* Authentication failures
* SonarQube server unavailable
* Quality gate violations

---

# Interview Questions

Q: What is SonarQube?

A:

A platform for static code analysis that helps identify bugs, vulnerabilities, and maintainability issues before deployment.

Q: What is a Quality Gate?

A:

A set of rules that determine whether code is allowed to progress through the delivery pipeline.

---

# Concepts Learned

* SAST
* Code Quality
* Technical Debt
* Quality Gates
* Secure Development
* DevSecOps
