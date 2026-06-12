# Jenkins CI Pipeline

## Overview

Jenkins is an open-source automation server used to implement Continuous Integration (CI) and Continuous Delivery (CD).

In this platform, Jenkins automates:

* Source Code Retrieval
* Application Build
* Static Code Analysis
* Security Scanning
* Docker Image Creation
* Container Registry Push

Without Jenkins, these tasks would need to be executed manually.

---

# Why Jenkins Was Introduced

Before CI:

Developer
↓
Manual Build
↓
Manual Test
↓
Manual Docker Build
↓
Manual Deployment

Problems:

* Human error
* Inconsistent deployments
* Slow release cycles
* Lack of repeatability

CI solves these problems through automation.

---

# Jenkins Architecture

Developer
↓
GitHub Push
↓
Jenkins Pipeline
↓
SonarQube Scan
↓
Trivy Scan
↓
Docker Build
↓
Push To ECR

---

# Jenkins Components

## Jenkins Controller

The controller manages:

* Pipelines
* Build execution
* Plugin management
* Credentials

---

## Jenkins Agents

Agents execute workloads.

Examples:

* Maven builds
* Docker builds
* Security scans

Large enterprises often use Kubernetes-based Jenkins agents.

---

# Pipeline Stages

## Stage 1 – Source Retrieval

Jenkins retrieves source code from GitHub.

Example:

```bash
git clone <repository>
```

Purpose:

* Obtain latest code
* Trigger automated workflow

---

## Stage 2 – Maven Build

Build application artifact.

Example:

```bash
mvn clean package
```

Output:

```text
target/application.jar
```

---

## Stage 3 – SonarQube Analysis

Static code quality analysis.

Purpose:

* Detect code smells
* Identify bugs
* Enforce quality gates

---

## Stage 4 – Trivy Scan

Container security scanning.

Purpose:

* Detect vulnerabilities
* Identify outdated packages
* Improve container security posture

---

## Stage 5 – Docker Build

Create container image.

Example:

```bash
docker build -t auth-service:v1 .
```

---

## Stage 6 – Push To Amazon ECR

Store image in registry.

Example:

```bash
docker push account-id.dkr.ecr.region.amazonaws.com/auth-service:v1
```

---

# Why CI Matters

Benefits:

* Consistency
* Repeatability
* Faster releases
* Reduced manual effort
* Improved security

---

# Common Jenkins Commands

Restart Jenkins:

```bash
sudo systemctl restart jenkins
```

Check Jenkins Status:

```bash
sudo systemctl status jenkins
```

View Logs:

```bash
sudo journalctl -u jenkins -f
```

---

# Common Failure Scenarios

## Build Failure

Possible Causes:

* Compilation errors
* Dependency issues
* Incorrect Maven configuration

---

## SonarQube Failure

Possible Causes:

* Quality gate violation
* Authentication issues
* SonarQube unavailable

---

## Docker Failure

Possible Causes:

* Invalid Dockerfile
* Docker daemon unavailable
* Missing permissions

---

## ECR Push Failure

Possible Causes:

* Expired login token
* IAM permission issues
* Incorrect repository name

---

# Interview Questions

Q: What is Continuous Integration?

A:

Continuous Integration is the practice of automatically building, testing, and validating code changes whenever developers commit code to a repository.

---

Q: Why use Jenkins?

A:

Jenkins automates software delivery workflows, improves consistency, reduces manual effort, and enables repeatable deployments.

---

Q: What is a Jenkins Pipeline?

A:

A Jenkins Pipeline is a series of automated stages that define how code moves from source control through build, testing, scanning, and deployment.

---

# Concepts Learned

* Continuous Integration
* Jenkins Controller
* Jenkins Agents
* Pipeline Stages
* Maven Build
* Docker Build
* ECR Push
* Automation
* DevSecOps
* CI/CD
