# Troubleshooting Guide

## Purpose

This document captures issues encountered during project implementation and their resolutions.

Goals:

* Reduce repeated troubleshooting
* Build operational knowledge
* Create a reusable engineering reference
* Improve incident response skills

---

# Issue 001 - Maven Build Failure Due To Malformed POM

## Symptoms

Command:

```bash
mvn clean package
```

Error:

```text
Malformed POM
expected START_TAG or END_TAG not TEXT
```

## Root Cause

Markdown code block markers were accidentally pasted into:

```text
pom.xml
```

Example:

```xml
```

<modelVersion>4.0.0</modelVersion>

```
```

These backticks are invalid XML.

## Resolution

Remove all markdown markers.

Keep only valid XML.

Rebuild:

```bash
mvn clean package
```

## Result

Build successful.

---

# Issue 002 - Docker Command Not Found

## Symptoms

Command:

```bash
docker --version
```

Error:

```text
docker: command not found
```

## Root Cause

Docker Desktop was not available in the terminal environment.

## Diagnosis

Verify:

```bash
which docker
```

Check PATH:

```bash
echo $PATH
```

## Resolution

Install Docker Desktop.

Verify:

```bash
docker --version
```

## Result

Docker Version 29.5.2 available.

---

# Issue 003 - Helm Not Installed

## Symptoms

Command:

```bash
helm version
```

Error:

```text
helm: command not found
```

## Root Cause

Helm was not installed on the workstation.

## Resolution

Install Helm using:

```powershell
winget install Helm.Helm
```

Verify:

```powershell
helm version
```

## Result

Helm installed successfully.

---

# Issue 004 - Helm Installed But Command Not Found

## Symptoms

Installation completed successfully:

```text
Successfully installed
```

But:

```powershell
helm version
```

returned:

```text
CommandNotFoundException
```

## Root Cause

PATH environment variable not refreshed.

## Resolution

Close all terminals.

Open a new PowerShell window.

Run:

```powershell
helm version
```

If issue persists:

```powershell
where.exe helm
```

Locate installation path.

Add Helm path to environment variables.

## Result

Pending Verification.

---

# Issue 005 - Chocolatey Lock File Error

## Symptoms

Command:

```powershell
choco install kubernetes-helm -y
```

Error:

```text
Unable to obtain lock file access
```

## Root Cause

Chocolatey lock file left behind from previous operation.

Potential causes:

* Interrupted installation
* Another Chocolatey process running
* Permission issues

## Resolution

Use alternative installer:

```powershell
winget install Helm.Helm
```

or remove stale lock file.

## Result

Resolved by switching installer.

---

# Issue 006 - AWS Authentication Validation

## Symptoms

Need to verify active AWS credentials.

## Diagnosis

Run:

```bash
aws sts get-caller-identity
```

Output:

```json
{
  "Account": "761018849945",
  "Arn": "arn:aws:iam::761018849945:user/Admin-User"
}
```

## Result

AWS CLI configured correctly.

---

# Troubleshooting Workflow

Step 1

Read Error Carefully

---

Step 2

Identify Component

Examples:

* Docker
* Maven
* Kubernetes
* Terraform
* AWS

---

Step 3

Verify Configuration

Examples:

```bash
docker version

kubectl version

terraform version

aws sts get-caller-identity
```

---

Step 4

Determine Root Cause

Do not guess.

Gather evidence.

---

Step 5

Apply Fix

Verify result.

Document resolution.

---

# Lessons Learned

Every issue solved becomes future knowledge.

The goal is not to avoid problems.

The goal is to solve problems systematically and document the solution.

# Issue 007 - ECR Repository Does Not Exist

## Symptoms

Command:

```bash
docker push ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/auth-service:v1
```

Error:

```text
The repository with name 'auth-service' does not exist
```

## Root Cause

One of the following:

* Repository not created
* Wrong AWS region
* Incorrect repository URI
* Attempting to push before repository creation

## Diagnosis

Verify current region:

```bash
aws configure get region
```

Verify repositories:

```bash
aws ecr describe-repositories
```

Verify repository URI:

```bash
aws ecr describe-repositories \
--query "repositories[*].[repositoryName,repositoryUri]"
```

## Resolution

Create repository:

```bash
aws ecr create-repository \
--repository-name auth-service
```

Verify repository creation:

```bash
aws ecr describe-repositories \
--query "repositories[*].[repositoryName,repositoryUri]"
```

## Lesson Learned

ECR repositories are region-specific resources.

Always verify:

* AWS Region
* Repository Name
* Repository URI

before tagging and pushing images.

---

# Issue 008 - Docker Tag Does Not Exist

## Symptoms

Command:

```bash
docker push ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/auth-service:v1
```

Error:

```text
tag does not exist
```

## Root Cause

Docker image was not tagged with the ECR repository URI.

Existing image:

```text
auth-service:v1
```

Expected image:

```text
ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/auth-service:v1
```

## Diagnosis

Verify local images:

```bash
docker images
```

Check whether ECR-tagged image exists.

## Resolution

Create ECR tag:

```bash
docker tag auth-service:v1 \
ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/auth-service:v1
```

Verify:

```bash
docker images
```

Push image:

```bash
docker push \
ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/auth-service:v1
```

## Lesson Learned

Docker can only push images that exist locally with the exact repository and tag being referenced.

---

# Issue 009 - ECR Region Tag Mismatch

## Symptoms

Repository exists:

```text
761018849945.dkr.ecr.ca-central-1.amazonaws.com/auth-service
```

But Docker image is tagged as:

```text
761018849945.dkr.ecr.us-east-1.amazonaws.com/auth-service:v1
```

Push fails or targets the wrong registry.

## Root Cause

Image was tagged using the wrong AWS region.

Current AWS Region:

```text
ca-central-1
```

Image Tag:

```text
us-east-1
```

Repository Region:

```text
ca-central-1
```

## Diagnosis

Verify configured region:

```bash
aws configure get region
```

Verify repositories:

```bash
aws ecr describe-repositories \
--query "repositories[*].[repositoryName,repositoryUri]"
```

Verify image tags:

```bash
docker images
```

## Resolution

Retag image using the correct ECR URI:

```bash
docker tag auth-service:v1 \
761018849945.dkr.ecr.ca-central-1.amazonaws.com/auth-service:v1
```

Verify:

```bash
docker images
```

Push:

```bash
docker push \
761018849945.dkr.ecr.ca-central-1.amazonaws.com/auth-service:v1
```

Optional cleanup:

```bash
docker rmi \
761018849945.dkr.ecr.us-east-1.amazonaws.com/auth-service:v1
```

## Lesson Learned

Always copy the repository URI directly from ECR.

Never assume the region.

Verify:

```bash
aws configure get region
```

before tagging and pushing images.

---

# Engineering Pattern Learned

When Docker push fails:

Step 1:

```bash
aws configure get region
```

Step 2:

```bash
aws ecr describe-repositories
```

Step 3:

```bash
docker images
```

Step 4:

Verify:

* Region
* Repository
* Tag
* Login

Step 5:

Retag and push.

This process eliminates most ECR push issues.

Issue 010 — Yes, Keep It

This is a genuine troubleshooting scenario.

You learned that:

ECR Repository Exists
≠
Image Exists In ECR

You had:

{
  "imageDetails": []
}

which proved the repository existed but contained no images.

That's a valuable lesson and something that can happen in Jenkins pipelines.


Issue 013 - EKS Endpoint No Such Host

Symptoms

kubectl get nodes

returns:

Unable to connect to the server:
lookup <eks-endpoint>: no such host

Root Cause

Common causes:

EKS cluster deleted
kubeconfig references old cluster
wrong AWS region
cluster recreated with new endpoint

Diagnosis

aws eks list-clusters --region ca-central-1

aws eks list-clusters --region us-east-1

kubectl config current-context

Resolution

Update kubeconfig:

aws eks update-kubeconfig \
--region REGION \
--name CLUSTER_NAME

Lesson Learned

kubectl relies on kubeconfig. If kubeconfig points to a deleted cluster, kubectl cannot communicate with EKS

## Issue 014 - Terraform Init Fails Due To Insufficient Disk Space

### Symptoms

Command:

terraform init

Error:

There is not enough space on the disk

### Root Cause

Terraform could not download required providers because the local system drive was full.

Example:

C: Drive Free Space = 0 GB

### Diagnosis

PowerShell:

Get-PSDrive C

Expected:

Free space greater than 5 GB.

Problem Example:

Free Space = 0 GB

### Additional Investigation

Check Windows.old size:

(Get-ChildItem "C:\Windows.old" -Recurse -File -ErrorAction SilentlyContinue |
Measure-Object -Property Length -Sum).Sum / 1GB

Result:

20.86 GB

### Resolution

1. Move important files from Windows.old
2. Delete Windows.old using Disk Cleanup
3. Remove unused Docker images
4. Clear temporary files
5. Rerun terraform init

### Verification

terraform init

Expected:

Terraform providers download successfully.

### Lesson Learned

Terraform provider installation requires local disk space. Infrastructure automation failures may be caused by workstation resource constraints rather than Terraform configuration issues.
