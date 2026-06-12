# Runbook 02 - Docker Desktop Installation and Verification

## Objective

Install Docker Desktop on Windows and verify that Docker is properly configured for local container development.

This environment will be used to:

* Build Docker Images
* Run Containers Locally
* Push Images to Amazon ECR
* Test Applications Before EKS Deployment

---

# Why Docker Is Required

Kubernetes does not deploy source code.

Kubernetes deploys container images.

Application Lifecycle:

Java Source Code
↓
Maven Build
↓
JAR File
↓
Docker Image
↓
Container
↓
Amazon ECR
↓
Amazon EKS

Docker is the bridge between application development and Kubernetes deployment.

---

# Environment

Operating System:

Windows 10

Development Environment:

VS Code

Shell:

Git Bash

Container Runtime:

Docker Desktop

WSL Version:

WSL2

---

# Verify WSL Installation

Open PowerShell:

```powershell
wsl --status
```

Expected Output:

```text
Default Distribution: docker-desktop
Default Version: 2
```

Purpose:

Confirms Docker Desktop is using WSL2 as its backend.

---

# Verify Docker Installation

Open Git Bash:

```bash
docker --version
```

Actual Output:

```text
Docker version 29.5.2
```

Purpose:

Confirms Docker CLI is installed and available in PATH.

---

# Verify Docker Daemon

Run:

```bash
docker ps
```

Expected Output:

```text
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

Purpose:

Confirms Docker Engine is running.

If an error occurs:

```text
Cannot connect to the Docker daemon
```

Start Docker Desktop and wait until:

```text
Engine Running
```

appears.

---

# Verify Docker Information

Run:

```bash
docker info
```

Purpose:

Displays:

* Docker Version
* Container Runtime
* Storage Driver
* Running Containers
* CPU Allocation
* Memory Allocation

Useful for troubleshooting.

---

# Verify Docker Images

Run:

```bash
docker images
```

Purpose:

Lists locally stored Docker images.

Example:

```text
REPOSITORY      TAG
auth-service    v1
```

---

# Verify Docker Containers

Run:

```bash
docker ps -a
```

Purpose:

Lists all containers, including stopped containers.

---

# Common Docker Commands

## Build Image

```bash
docker build -t auth-service:v1 .
```

Purpose:

Creates a Docker image from a Dockerfile.

---

## Run Container

```bash
docker run -d -p 8080:8080 auth-service:v1
```

Purpose:

Starts a container in detached mode.

---

## View Running Containers

```bash
docker ps
```

---

## View Container Logs

```bash
docker logs CONTAINER_ID
```

---

## Stop Container

```bash
docker stop CONTAINER_ID
```

---

## Remove Container

```bash
docker rm CONTAINER_ID
```

---

## Remove Image

```bash
docker rmi IMAGE_ID
```

---

# Troubleshooting

## Docker Command Not Found

Error:

```text
docker: command not found
```

Cause:

Docker Desktop not installed or PATH not configured.

Solution:

* Install Docker Desktop
* Restart terminal
* Verify PATH configuration

---

## Docker Daemon Not Running

Error:

```text
Cannot connect to the Docker daemon
```

Solution:

Start Docker Desktop.

---

## Port Already In Use

Error:

```text
Bind for 0.0.0.0:8080 failed
```

Cause:

Another process is using port 8080.

Solution:

Identify process:

```bash
netstat -ano | findstr 8080
```

Stop process or use a different port.

---

# Commands Used During Verification

```bash
docker --version

docker ps

docker info

docker images

docker ps -a
```

---

# Skills Learned

* Docker Desktop Installation
* WSL2 Integration
* Docker CLI
* Docker Engine Verification
* Container Runtime Concepts
* Local Container Development

---

# Next Module

Auth Service Containerization

Flow:

Spring Boot Application
↓
Maven Build
↓
Dockerfile
↓
Docker Image
↓
Container
↓
Local Testing
↓
Amazon ECR
↓
Amazon EKS
