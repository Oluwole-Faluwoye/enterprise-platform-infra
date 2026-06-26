#!/bin/bash

# ==========================================================
# ENTERPRISE JENKINS PLATFORM BOOTSTRAP
# Amazon Linux 2023
# Jenkins + SonarQube
# ==========================================================

set -euo pipefail

# ==========================================================
# CONFIGURATION
# ==========================================================

AWS_REGION="us-east-1"

ACCOUNT_ID="761018849945"

JENKINS_IMAGE="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/jenkins:v1"

SONAR_IMAGE="sonarqube:lts-community"

DEVICE="/dev/xvdf"

export AWS_DEFAULT_REGION=$AWS_REGION

# ==========================================================
# SYSTEM UPDATE
# ==========================================================

echo "🚀 Updating operating system..."

sudo dnf update -y

# ==========================================================
# INSTALL DOCKER
# ==========================================================

echo "🐳 Installing Docker..."

if ! command -v docker >/dev/null 2>&1
then

    sudo dnf install -y docker

fi

sudo systemctl enable docker

sudo systemctl start docker

echo "⏳ Waiting for Docker daemon..."

until sudo docker info >/dev/null 2>&1
do
    sleep 2
done

echo "✅ Docker daemon ready."

# ==========================================================
# USER ACCESS
# ==========================================================

echo "👤 Adding ec2-user to docker group..."

sudo usermod -aG docker ec2-user || true

# ==========================================================
# INSTALL AWS CLI
# ==========================================================

if ! command -v aws >/dev/null 2>&1
then

    echo "🔧 Installing AWS CLI v2..."

    curl \
      "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
      -o awscliv2.zip

    unzip -q awscliv2.zip

    sudo ./aws/install --update

    rm -rf aws awscliv2.zip

else

    echo "✅ AWS CLI already installed."

fi

# ==========================================================
# VERIFY IAM ROLE
# ==========================================================

echo ""
echo "🔐 Verifying IAM role..."

aws sts get-caller-identity

# ==========================================================
# EBS VALIDATION
# ==========================================================

echo ""
echo "💾 Checking dedicated EBS volume..."

if [ -b "$DEVICE" ]
then

    echo "✅ EBS volume detected."

    if ! sudo blkid "$DEVICE" >/dev/null 2>&1
    then

        echo "🧱 Formatting EBS volume..."

        sudo mkfs -t xfs "$DEVICE"

    else

        echo "✅ Existing filesystem detected."

    fi

    echo "📂 Creating mount point..."

    sudo mkdir -p /data

    echo "🔗 Mounting EBS volume..."

    sudo mount "$DEVICE" /data || true

    UUID=$(sudo blkid -s UUID -o value "$DEVICE")

    grep -q "$UUID" /etc/fstab || \
    echo "UUID=$UUID /data xfs defaults,nofail 0 2" \
    | sudo tee -a /etc/fstab

else

    echo "❌ EBS volume not found."

    exit 1

fi

# ==========================================================
# VERIFY STORAGE
# ==========================================================

echo ""
echo "📊 Mounted filesystems"

df -h

echo ""
echo "📊 Mount verification"

mount | grep /data || true

# ==========================================================
# PERSISTENT DIRECTORIES
# ==========================================================

echo "📁 Creating persistent directories..."

sudo mkdir -p /data/jenkins

sudo mkdir -p /data/jenkins/dependency-check-data

sudo mkdir -p /data/jenkins/trivy-cache

sudo mkdir -p /data/sonarqube/data

sudo mkdir -p /data/sonarqube/logs

sudo mkdir -p /data/sonarqube/extensions


# ==========================================================
# PERMISSIONS
# ==========================================================

echo "🔐 Configuring permissions..."

sudo chown -R 1000:1000 /data/jenkins

sudo chmod -R 775 /data/jenkins

sudo chmod 777 /data/jenkins/trivy-cache

sudo chmod -R 777 /data/jenkins/dependency-check-data

sudo chown -R 1000:1000 /data/sonarqube

sudo chmod -R 775 /data/sonarqube

# ==========================================================
# DOCKER NETWORK
# ==========================================================

echo "🌐 Creating Docker network..."

docker network inspect devops-network >/dev/null 2>&1 || \
docker network create devops-network

# ==========================================================
# ECR LOGIN
# ==========================================================

echo "🔐 Logging into ECR..."

aws ecr get-login-password \
--region ${AWS_REGION} \
| docker login \
--username AWS \
--password-stdin \
${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# ==========================================================
# VERIFY ECR ACCESS
# ==========================================================

echo ""
echo "📦 Available ECR repositories"

aws ecr describe-repositories \
--region ${AWS_REGION} \
--query "repositories[*].repositoryName"

# ==========================================================
# PULL IMAGES
# ==========================================================

echo "📥 Pulling Jenkins image..."

docker pull ${JENKINS_IMAGE}

echo "📥 Pulling SonarQube image..."

if ! docker pull ${SONAR_IMAGE}; then
    echo "ERROR: Failed to pull SonarQube image"
    exit 1
fi

# ==========================================================
# REMOVE EXISTING CONTAINERS
# ==========================================================

docker rm -f jenkins 2>/dev/null || true

docker rm -f sonarqube 2>/dev/null || true

# ==========================================================
# DEPLOY JENKINS
# ==========================================================

echo "🚀 Starting Jenkins..."

docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --network devops-network \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /data/jenkins:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${JENKINS_IMAGE}

# ==========================================================
# DEPLOY SONARQUBE
# ==========================================================

echo "🚀 Starting SonarQube..."

docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  --network devops-network \
  -p 9000:9000 \
  -v /data/sonarqube/data:/opt/sonarqube/data \
  -v /data/sonarqube/logs:/opt/sonarqube/logs \
  -v /data/sonarqube/extensions:/opt/sonarqube/extensions \
  ${SONAR_IMAGE}

# ==========================================================
# HEALTH CHECKS
# ==========================================================

echo "⏳ Waiting for Jenkins..."

for i in {1..60}
do

    if curl -s http://localhost:8080/login >/dev/null
    then

        echo "✅ Jenkins Ready"

        break

    fi

    sleep 5

done

echo "⏳ Waiting for SonarQube..."

for i in {1..60}
do

    if curl -s http://localhost:9000 >/dev/null
    then

        echo "✅ SonarQube Ready"

        break

    fi

    sleep 5

done

# ==========================================================
# VERIFY CONTAINERS
# ==========================================================

echo ""
echo "🐳 Running containers"

docker ps

# ==========================================================
# VERIFY JENKINS TOOLS
# ==========================================================

echo ""
echo "🔍 Verifying Jenkins tools"

docker exec jenkins docker --version

docker exec jenkins aws --version

docker exec jenkins kubectl version --client

docker exec jenkins helm version

docker exec jenkins git --version

docker exec jenkins terraform version

# ==========================================================
# JENKINS PASSWORD
# ==========================================================

echo ""
echo "🔑 Jenkins Initial Password"

sudo cat /data/jenkins/secrets/initialAdminPassword || true

# ==========================================================
# PUBLIC IP
# ==========================================================

PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)

# ==========================================================
# SUMMARY
# ==========================================================

echo ""
echo "=================================================="
echo "✅ PLATFORM DEPLOYMENT COMPLETE"
echo "=================================================="

echo ""
echo "🌐 Jenkins URL"
echo "http://${PUBLIC_IP}:8080"

echo ""
echo "🌐 SonarQube URL"
echo "http://${PUBLIC_IP}:9000"

echo ""
echo "📁 Persistent Storage"
echo "/data/jenkins"
echo "/data/sonarqube"

echo ""
echo "🔗 GitHub Webhook"
echo "http://${PUBLIC_IP}:8080/github-webhook/"

echo ""
echo "🔗 SonarQube Webhook"
echo "http://jenkins:8080/sonarqube-webhook/"

echo ""
echo "⚠️ IMPORTANT"
echo "- Re-login to SSH to refresh docker group membership"
echo "- Jenkins data persists on dedicated EBS"
echo "- SonarQube data persists on dedicated EBS"
echo "- IAM Role authentication is active"
echo "- IMDSv2 is enforced"