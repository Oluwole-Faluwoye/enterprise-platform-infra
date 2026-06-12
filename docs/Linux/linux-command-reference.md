# Linux Command Reference

## Overview

This document contains Linux, Git Bash, Kubernetes, Docker, Terraform, AWS CLI, and DevOps commands used throughout the project.

---

# Navigation Commands

## Show Current Directory

```bash
pwd
```

Purpose:

Displays current working directory.

Example:

```bash
pwd
```

Output:

```text
/home/ec2-user/project
```

---

## List Files

```bash
ls
```

Purpose:

Displays files and folders.

Examples:

```bash
ls

ls -l

ls -la
```

---

## Change Directory

```bash
cd
```

Examples:

```bash
cd services/auth-service

cd ..

cd ~
```

---

# Directory Commands

## Create Directory

```bash
mkdir
```

Examples:

```bash
mkdir docs

mkdir scripts
```

---

## Create Nested Directories

```bash
mkdir -p
```

Examples:

```bash
mkdir -p docs/concepts

mkdir -p src/main/java
```

---

## Remove Directory

```bash
rm -rf
```

Example:

```bash
rm -rf auth-service
```

Warning:

Deletes recursively.

Use carefully.

---

# File Commands

## Create Empty File

```bash
touch
```

Examples:

```bash
touch README.md

touch Dockerfile

touch app.yaml
```

---

## Display File Contents

```bash
cat
```

Examples:

```bash
cat pom.xml

cat application.yml
```

---

## Display File With Line Numbers

```bash
cat -n
```

Example:

```bash
cat -n pom.xml
```

Useful for debugging.

---

# Search Commands

## Find Files

```bash
find
```

Examples:

```bash
find . -type f

find . -name "*.yaml"
```

---

## Find Directories

```bash
find . -type d
```

---

# Git Commands

## Check Status

```bash
git status
```

---

## Add Files

```bash
git add .
```

---

## Commit Changes

```bash
git commit -m "message"
```

---

## Push To Remote

```bash
git push
```

---

## Pull Latest Changes

```bash
git pull
```

---

# Maven Commands

## Build Application

```bash
mvn clean package
```

Purpose:

Compile Java source code and generate JAR.

---

## Run Tests

```bash
mvn test
```

---

# Docker Commands

## Build Image

```bash
docker build -t auth-service:v1 .
```

---

## View Images

```bash
docker images
```

---

## Run Container

```bash
docker run -d -p 8080:8080 auth-service:v1
```

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

# Kubernetes Commands

## Cluster Information

```bash
kubectl cluster-info
```

---

## Get Nodes

```bash
kubectl get nodes
```

---

## Get Pods

```bash
kubectl get pods
```

---

## Get All Pods

```bash
kubectl get pods -A
```

---

## Describe Pod

```bash
kubectl describe pod POD_NAME
```

---

## View Pod Logs

```bash
kubectl logs POD_NAME
```

---

## Apply Manifest

```bash
kubectl apply -f deployment.yaml
```

---

## Delete Resource

```bash
kubectl delete -f deployment.yaml
```

---

# Terraform Commands

## Initialize

```bash
terraform init
```

---

## Validate

```bash
terraform validate
```

---

## Plan

```bash
terraform plan
```

---

## Apply

```bash
terraform apply
```

---

## Destroy

```bash
terraform destroy
```

---

# AWS CLI Commands

## Verify Identity

```bash
aws sts get-caller-identity
```

---

## List S3 Buckets

```bash
aws s3 ls
```

---

## List EKS Clusters

```bash
aws eks list-clusters
```

---

## Update Kubeconfig

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name cluster-name
```

---

# Helm Commands

## Install Chart

```bash
helm install app .
```

---

## Upgrade Chart

```bash
helm upgrade app .
```

---

## List Releases

```bash
helm list
```

---

## Remove Release

```bash
helm uninstall app
```

# Helm Commands

## Verify Installation

```bash
helm version
```

## Create Chart

```bash
helm create auth-service
```

## Install Chart

```bash
helm install auth-service .
```

## Upgrade Chart

```bash
helm upgrade auth-service .
```

## List Releases

```bash
helm list
```

## Remove Release

```bash
helm uninstall auth-service
```

# Docker Space Management Commands

## Show Docker Disk Usage

```bash
docker system df
```

Displays:

* Images
* Containers
* Volumes
* Build Cache

---

## Show Images

```bash
docker images
```

---

## Show Containers

```bash
docker ps -a
```

---

## Remove Stopped Containers

```bash
docker container prune
```

---

## Remove Unused Images

```bash
docker image prune
```

---

## Remove All Unused Docker Resources

```bash
docker system prune -a
```

Use with caution.

---

## Remove Specific Image

```bash
docker rmi IMAGE_NAME
```

Example:

```bash
docker rmi \
761018849945.dkr.ecr.us-east-1.amazonaws.com/auth-service:v1
```

helm lint helm/auth-service

Purpose:

Validates Helm chart syntax before deployment.

This command is used constantly in CI/CD pipelines before:

helm install

helm upgrade

Fix the indentation, run:

helm lint helm/auth-service

and paste the output. That is the next production-grade verification step before we render the templates again.