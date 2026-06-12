#!/bin/bash

# -----------------------------------------------------------------------------
# Strict Mode & Logging Setup
# -----------------------------------------------------------------------------
set -euo pipefail

LOG_FILE="/var/log/bootstrap-tools.log"
exec > >(tee -a "$LOG_FILE") 2>&1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}[$(date +'%Y-%m-%dT%H:%M:%S%z')] INFO: $1${NC}"; }
log_success() { echo -e "${GREEN}[$(date +'%Y-%m-%dT%H:%M:%S%z')] SUCCESS: $1${NC}"; }
log_error() { echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')] ERROR: $1${NC}"; }

trap 'log_error "Command failed at line $LINENO. Check logs for details."; exit 1' ERR

log_info "Starting Dynamic DevSecOps Tooling Bootstrap..."

# -----------------------------------------------------------------------------
# Core Dependencies
# -----------------------------------------------------------------------------
log_info "Updating system and installing core utilities..."
# 1. Force swap curl-minimal for the full curl package
yum install -y curl --allowerasing
yum update -y
yum install -y git wget unzip yum-utils jq
log_success "System updated."

# -----------------------------------------------------------------------------
# Languages, Build Tools & CI/CD
# -----------------------------------------------------------------------------
log_info "Installing Java 21, Node.js, Maven, Jenkins, and Ansible..."
dnf install -y java-21-amazon-corretto nodejs maven ansible

wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins
systemctl enable --now jenkins
log_success "Build tools and Jenkins installed."

# -----------------------------------------------------------------------------
# Cloud & IaC
# -----------------------------------------------------------------------------
log_info "Installing Latest AWS CLI v2 and Terraform..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip && ./aws/install && rm -rf awscliv2.zip aws

yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform vault
log_success "Cloud CLI tools installed."

# -----------------------------------------------------------------------------
# Docker & Security Tooling
# -----------------------------------------------------------------------------
log_info "Installing Docker Engine & SonarQube..."
yum install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user
# Add Jenkins to the Docker group
usermod -aG docker jenkins
# Restart Jenkins so the running daemon inherits the new Docker group permissions!
log_info "Restarting Jenkins to apply Docker group permissions..."
systemctl restart jenkins

# Dynamically fetch the latest Docker Compose release from GitHub API
log_info "Fetching Latest Docker Compose..."
LATEST_COMPOSE=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sL "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

log_info "Starting SonarQube Container (Latest LTS)..."
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

# Dynamically fetch the latest Trivy using their official installer
log_info "Installing Latest Trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
log_success "Containers and Security tooling installed."

# -----------------------------------------------------------------------------
# Kubernetes Utilities (Dynamic Latest Stable Versions)
# -----------------------------------------------------------------------------
log_info "Fetching Latest Stable Kubectl..."
KUBECTL_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -sLO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/linux/amd64/kubectl"
chmod +x ./kubectl && mv ./kubectl /usr/local/bin/

log_info "Fetching Latest eksctl..."
curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin/

log_info "Fetching Latest Helm..."
curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
log_success "Kubernetes utilities installed."

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
log_info "Installing MariaDB and PostgreSQL 15..."
yum install -y mariadb105-server postgresql15 postgresql15-server

# Start MariaDB
systemctl enable --now mariadb

# Initialize PostgreSQL ONLY if it hasn't been initialized yet
log_info "Configuring PostgreSQL..."
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
    log_info "Initializing fresh PostgreSQL database..."
    # Clear directory in case of leftover fragments from a crashed run
    rm -rf /var/lib/pgsql/data/* 
    postgresql-setup --initdb
else
    log_info "PostgreSQL already initialized. Skipping initdb."
fi

systemctl enable --now postgresql
log_success "Databases installed and running."

# -----------------------------------------------------------------------------
# Version Audit Trail
# -----------------------------------------------------------------------------
log_info "--- INSTALLED VERSIONS ---"
git --version
java -version 2>&1 
terraform -v 
docker --version
docker-compose --version
trivy --version 
kubectl version --client -o yaml | grep gitVersion | awk '{print "Kubectl: " $2}'
helm version --short