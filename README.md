# 🚀 AWS EKS DevSecOps Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.12+-7B42BC?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20EC2%20%7C%20ECR-FF9900?style=for-the-badge&logo=amazon-aws)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?style=for-the-badge&logo=kubernetes)](https://kubernetes.io/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins)](https://www.jenkins.io/)
[![IaC](https://img.shields.io/badge/IaC-Infrastructure%20as%20Code-blue?style=for-the-badge)](https://en.wikipedia.org/wiki/Infrastructure_as_code)
[![DevSecOps](https://img.shields.io/badge/DevSecOps-Zero%20Trust-green?style=for-the-badge)](https://www.devsecops.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-brightgreen?style=for-the-badge)](https://github.com/LearningGallery/AWS-EKS-DevSecOps-Project)
[![Last Updated](https://img.shields.io/badge/Last%20Updated-2025-blue?style=for-the-badge)](https://github.com/LearningGallery/AWS-EKS-DevSecOps-Project)

> **Enterprise-grade AWS EKS DevSecOps platform featuring a CSV-driven Infrastructure-as-Code engine, Zero Trust security architecture, fully automated CI/CD pipelines with Jenkins, and a microservices deployment of Google's Online Boutique on Kubernetes — all provisioned with Terraform.**

---

## 📋 Table of Contents

- [Quick Summary](#-quick-summary)
- [Architecture Summary](#-architecture-summary)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Features & Capabilities](#-features--capabilities)
- [Cloud Provider & Resources](#-cloud-provider--resources)
- [Module Summary](#-module-summary)
- [Variable Reference](#-variable-reference)
- [Outputs Reference](#-outputs-reference)
- [Documentation](#-documentation)
- [Prerequisites & Requirements](#-prerequisites--requirements)
- [How to Use (By Scenario)](#-how-to-use-by-scenario)
- [State Management](#-state-management)
- [Security Considerations](#-security-considerations)
- [Cost Considerations](#-cost-considerations)
- [Troubleshooting](#-troubleshooting)
- [Examples](#-examples)
- [Contributing](#-contributing)
- [Roadmap](#-roadmap)
- [License & Contact](#-license--contact)

---

## 🎯 Quick Summary

### What Does This Deploy?

This project provisions a **complete, production-grade DevSecOps platform on AWS** — from foundational networking to a running Kubernetes cluster hosting an 11-service microservices application.

### What Problem Does It Solve?

| Problem | Solution |
|---------|----------|
| Manual, error-prone infrastructure provisioning | Fully automated Terraform IaC |
| Hardcoded values scattered across configs | CSV-driven data engine — change a spreadsheet, change infrastructure |
| Insecure container registries | ECR with KMS encryption, immutable tags, and lifecycle policies |
| Manual CI/CD pipeline per service | Jenkins Master Orchestrator builds and pushes all 11 services in sequence |
| No repeatable deployment process | GitOps pattern — Kubernetes YAML auto-updated by CI/CD |

### Who Should Use This?

- 🧑‍💻 **DevOps/Cloud Engineers** looking for a reference EKS platform
- 🎓 **Learners** studying AWS, Kubernetes, Terraform, and DevSecOps
- 🏢 **Teams** needing an enterprise-grade IaC starting point
- 🔒 **Security Engineers** interested in Zero Trust cloud architecture

### Key Benefits

- ✅ **CSV-Driven Configuration** — Add/remove infrastructure by editing a CSV file
- ✅ **Zero Trust Architecture** — KMS encryption, IMDSv2, immutable container tags
- ✅ **GitOps-Ready** — Jenkins pipelines auto-update Kubernetes YAML on every build
- ✅ **Reusable Modules** — 6 composable Terraform modules (VPC, EC2, EKS, ECR, IAM, S3)
- ✅ **Remote State** — S3 + native lock file for safe team collaboration
- ✅ **Production Patterns** — OIDC/IRSA, EKS access entries, NACLs, Security Groups

---

## 🏗️ Architecture Summary

This platform deploys a **three-tier AWS architecture** in `ap-southeast-1` (Singapore):

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────┐
│                  AWS VPC (10.0.0.0/16)              │
│                                                     │
│  ┌────────────────────┐  ┌────────────────────┐     │
│  │  Public Subnet AZ1 │  │  Public Subnet AZ2 │     │
│  │  10.0.1.0/24       │  │  10.0.2.0/24       │     │
│  │  [Jenkins / Mgmt]  │  │                    │     │
│  └────────────────────┘  └────────────────────┘     │
│              │                                      │
│  ┌────────────────────┐  ┌────────────────────┐     │
│  │  Private Subnet AZ1│  │  Private Subnet AZ2│     │
│  │  10.0.10.0/24      │  │  10.0.11.0/24      │     │
│  │  [EKS Node Group]  │  │  [EKS Node Group]  │     │
│  └────────────────────┘  └────────────────────┘     │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────┐    ┌─────────────────────┐
│  EKS Control Plane  │    │  ECR (11 Repos)     │
│  K8s v1.31          │◄───│  KMS Encrypted      │
│  KMS Secret Encrypt │    │  Immutable Tags     │
└─────────────────────┘    └─────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│              Online Boutique (11 Microservices)     │
│  frontend → checkoutservice → paymentservice        │
│  productcatalogservice → recommendationservice      │
│  cartservice (Redis) → currencyservice              │
│  adservice → emailservice → shippingservice         │
│  loadgenerator                                      │
└─────────────────────────────────────────────────────┘
```

### Resources Being Created

| Category | Resources |
|----------|-----------|
| **Network** | 1 VPC, 4 Subnets (2 public, 2 private), 1 IGW, Route Tables, NACLs, Security Groups |
| **Compute** | 1 Management EC2 (Jenkins/SonarQube/Tools), EKS Node Group (t3.large, 2-10 nodes) |
| **Container** | 1 EKS Cluster (K8s 1.31), 11 ECR Repositories |
| **Identity** | 3 IAM Roles (ec2-profile, eks-master, eks-node), OIDC Provider |
| **State** | 1 S3 State Bucket, 1 DynamoDB Lock Table |

> 📖 See [docs/02-ARCHITECTURE.md](docs/02-ARCHITECTURE.md) for full architecture details.

---

## ⚡ Quick Start

### Prerequisites Checklist

- [ ] AWS CLI v2 installed and configured
- [ ] Terraform >= 1.12.0 installed
- [ ] Git installed
- [ ] AWS IAM user/role with sufficient permissions
- [ ] SSH key pair created in AWS (`learninggallery` or your own)

### 5-Step Deployment

**Step 1: Clone the repository**
```bash
git clone https://github.com/LearningGallery/AWS-EKS-DevSecOps-Project.git
cd AWS-EKS-DevSecOps-Project
```

**Step 2: Deploy the bootstrap (state backend)**
```bash
cd Project/LearningGallery/Infra-Code_UAT/terraform-bootstrap
terraform init
terraform apply -auto-approve
# Note the output: state_bucket_names
```

**Step 3: Configure the backend**
```bash
cd ../
# Edit backend.tf — update bucket name from bootstrap output
# Default: st-cis-uat-tfstate-<YOUR_ACCOUNT_ID>
```

**Step 4: Initialize and plan**
```bash
terraform init
terraform plan -out=tfplan
```

**Step 5: Deploy**
```bash
terraform apply tfplan
# Estimated time: 15-25 minutes (EKS cluster creation dominates)
```

**Validate deployment:**
```bash
# Get kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

> 📖 Full tutorial: [docs/07-QUICK-START.md](docs/07-QUICK-START.md)

---

## 📁 Project Structure

```
AWS-EKS-DevSecOps-Project/
├── .gitignore                          # Excludes state, secrets, tfvars
├── README.md                           # This file
│
├── modules/                            # 🔧 REUSABLE TERRAFORM MODULES
│   ├── ec2/                            # EC2 instance provisioning
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── ecr/                            # ECR registry management
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── eks/                            # EKS cluster + node groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── output.tf
│   │   └── eks-jenkinsfile             # EKS-specific pipeline
│   ├── iam/                            # IAM roles + policies
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── s3/                             # S3 bucket management
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   └── vpc/                            # VPC + networking
│       ├── main.tf
│       ├── variables.tf
│       └── output.tf
│
└── Project/
    └── LearningGallery/
        ├── Infra-Code_UAT/             # 🏗️ MAIN INFRASTRUCTURE (UAT)
        │   ├── main.tf                 # Root orchestration (CSV engine)
        │   ├── variables.tf            # Global variables
        │   ├── output.tf               # Root outputs (commented)
        │   ├── provider.tf             # AWS provider config
        │   ├── backend.tf              # Remote state config
        │   │
        │   ├── data/                   # 📊 CSV DATA ENGINE
        │   │   ├── vpcs.csv            # VPC definitions
        │   │   ├── subnets.csv         # Subnet layout
        │   │   ├── sg_rules.csv        # Security group rules
        │   │   ├── nacl_rules.csv      # NACL rules
        │   │   ├── route_rules.csv     # Route table rules
        │   │   ├── infrastructure.csv  # EC2 instance definitions
        │   │   ├── iam_roles.csv       # IAM role definitions
        │   │   ├── ecr_repositories.csv # ECR repo list
        │   │   ├── eks_clusters.csv    # EKS cluster config
        │   │   ├── eks_node_groups.csv # EKS node group config
        │   │   └── bootstrap_backends.csv # State backend config
        │   │
        │   ├── policies/               # 🔐 IAM POLICY DOCUMENTS
        │   │   ├── eks_autoscaler_policy.json
        │   │   └── eks_custom_policy.json
        │   │
        │   ├── scripts/                # 🛠️ BOOTSTRAP SCRIPTS
        │   │   ├── updated_install-tools.sh  # Production bootstrap
        │   │   └── install-tools.sh          # Legacy bootstrap
        │   │
        │   └── terraform-bootstrap/    # 🥾 BOOTSTRAP MODULE
        │       ├── main.tf             # S3 + DynamoDB provisioning
        │       ├── variables.tf
        │       └── outputs.tf
        │
        └── Apps-Code_UAT/              # 🐳 APPLICATION CODE
            ├── jenkinsfiles/           # Per-service CI/CD pipelines
            │   ├── master-orchestrator # Builds all 11 services
            │   ├── adservice
            │   ├── cartservice
            │   ├── checkoutservice
            │   ├── currencyservice
            │   ├── emailservice
            │   ├── frontend
            │   ├── loadgenerator
            │   ├── paymentservice
            │   ├── productcatalogservice
            │   ├── recommendationservice
            │   └── shippingservice
            └── kubernetes-files/       # K8s deployment manifests
                ├── adservice.yaml
                ├── cartservice.yaml
                ├── checkoutservice.yaml
                ├── currencyservice.yaml
                ├── emailservice.yaml
                ├── frontend.yaml       # Includes LoadBalancer service
                ├── loadgenerator.yaml
                ├── paymentservice.yaml
                ├── productcatalogservice.yaml
                ├── recommendationservice.yaml
                ├── redis-cart.yaml
                └── shippingservice.yaml
```

---

## ✨ Features & Capabilities

### 🏗️ Infrastructure Provisioning
- **CSV-Driven Engine** — All infrastructure defined in CSV files; no HCL editing required for common changes
- **Multi-AZ VPC** — Public and private subnets across 2 availability zones
- **Security Layering** — Security Groups + NACLs for defense-in-depth
- **Internet Gateway** — Auto-created when public subnets exist

### 🔒 Zero Trust Security
- **IMDSv2 Enforcement** — EC2 instances require token-based metadata access
- **KMS Encryption** — EKS secrets and ECR images encrypted at rest
- **Immutable Container Tags** — Prevents image tag overwriting in ECR
- **Least Privilege IAM** — Separate roles for EC2, EKS control plane, and worker nodes
- **OIDC/IRSA Ready** — OpenID Connect provider created for pod-level IAM

### 🐳 Container Platform
- **EKS Cluster v1.31** — Managed Kubernetes with full control plane logging
- **Auto-scaling Node Group** — t3.large, 2-10 nodes on-demand
- **11 ECR Repositories** — One per microservice, with lifecycle cleanup policies
- **GitOps Pattern** — Jenkins updates Kubernetes YAML with new image tags post-build

### 🚀 CI/CD Pipeline
- **Master Orchestrator** — Single Jenkins pipeline builds and pushes all 11 services
- **Per-Service Pipelines** — Individual Jenkinsfiles for granular control
- **Traceable Image Tags** — Format: `<build_number>-<git_sha>` (e.g., `42-abc1234`)
- **Security Scanning** — Trivy IaC scanning integrated into EKS pipeline
- **Workspace Cleanup** — Automatic post-build cleanup prevents disk exhaustion

### 🛠️ Management Instance
- **All-in-One DevOps Server** — Jenkins, SonarQube, Docker, Trivy, kubectl, eksctl, Helm
- **Dynamic Tool Versions** — Bootstrap script fetches latest stable versions
- **Strict Mode Bootstrap** — `set -euo pipefail` with structured logging and error traps

---

## ☁️ Cloud Provider & Resources

| Module | Resources Created | Count | Purpose |
|--------|------------------|-------|---------|
| `vpc` | `aws_vpc` | 1 | Core network boundary |
| `vpc` | `aws_subnet` | 4 | 2 public (web), 2 private (eks) |
| `vpc` | `aws_internet_gateway` | 1 | Internet egress for public subnets |
| `vpc` | `aws_route_table` | 3 | 1 public, 2 private (by role) |
| `vpc` | `aws_security_group` | 2 | web-sg, eks-sg |
| `vpc` | `aws_security_group_rule` | 16+ | Inbound/outbound rules from CSV |
| `vpc` | `aws_network_acl` | 2 | Per-tier NACL (web, eks) |
| `vpc` | `aws_network_acl_rule` | 18 | Rules from nacl_rules.csv |
| `ec2` | `aws_instance` | 1 | Management/Jenkins server |
| `iam` | `aws_iam_role` | 3 | ec2-profile, eks-master, eks-node |
| `iam` | `aws_iam_policy` | 2 | Custom EKS + autoscaler policies |
| `iam` | `aws_iam_instance_profile` | 2 | ec2-profile, eks-node |
| `eks` | `aws_eks_cluster` | 1 | Kubernetes control plane |
| `eks` | `aws_kms_key` | 1 | EKS secret encryption |
| `eks` | `aws_eks_node_group` | 1 | Worker node group (ng_app) |
| `ecr` | `aws_ecr_repository` | 11 | One per microservice |
| `ecr` | `aws_ecr_lifecycle_policy` | 11 | Keep last 30 images |
| root | `aws_iam_openid_connect_provider` | 1 | OIDC for IRSA |
| root | `aws_eks_access_entry` | 1 | EC2 admin access to kubectl |
| bootstrap | `aws_s3_bucket` | 1 | Terraform state storage |
| bootstrap | `aws_dynamodb_table` | 1 | State locking |

---

## 📦 Module Summary

| Module | Purpose | Key Resources | Outputs |
|--------|---------|--------------|---------|
| `modules/vpc` | Complete VPC networking | VPC, Subnets, IGW, RT, SG, NACL | `vpc_id`, `subnet_ids`, `sg_ids` |
| `modules/ec2` | EC2 instance provisioning | aws_instance (with IMDSv2) | `instance_ids`, `private_ips`, `arns` |
| `modules/iam` | IAM roles and policies | Roles, Policies, Instance Profiles | `role_arns`, `instance_profile_names` |
| `modules/eks` | Kubernetes cluster | EKS Cluster, Node Group, KMS Key | `cluster_endpoint`, `cluster_name`, `oidc_issuer_url` |
| `modules/ecr` | Container registries | ECR Repos, Lifecycle Policies | `repository_urls`, `repository_arns` |
| `modules/s3` | S3 bucket management | Buckets, Versioning, Encryption | `bucket_names`, `bucket_arns` |

---

## 📝 Variable Reference

Variables are defined across multiple layers using the **CSV-driven engine pattern**:

| Layer | Location | Purpose |
|-------|----------|---------|
| Global variables | `variables.tf` | `aws_region` (default: `ap-southeast-1`) |
| VPC config | `data/vpcs.csv` | CIDR, project, environment, network zone |
| Subnet config | `data/subnets.csv` | Subnet layout, AZs, public/private |
| Security rules | `data/sg_rules.csv` | All security group rules |
| NACL rules | `data/nacl_rules.csv` | Network ACL rules |
| Route rules | `data/route_rules.csv` | Route table entries |
| EC2 config | `data/infrastructure.csv` | Instance types, AMIs, sizing |
| IAM config | `data/iam_roles.csv` | Roles, trusted services, policies |
| ECR config | `data/ecr_repositories.csv` | Repository list and settings |
| EKS clusters | `data/eks_clusters.csv` | Cluster config, K8s version |
| EKS nodes | `data/eks_node_groups.csv` | Node group sizing and types |

> 📖 Full variable documentation: [docs/05-VARIABLES-GUIDE.md](docs/05-VARIABLES-GUIDE.md)

---

## 📤 Outputs Reference

| Output | Description | Example Value |
|--------|-------------|---------------|
| `eks_cluster_name` | EKS cluster name | `cis-uat-eks_main` |
| `eks_cluster_endpoint` | K8s API endpoint | `https://XXXXX.gr7.ap-southeast-1.eks.amazonaws.com` |
| `eks_kubeconfig_command` | kubectl auth command | `aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main` |
| `ecr_repository_urls` | Map of ECR URLs | `{ "frontend" = "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-frontend" }` |
| `ec2_private_ips` | Management server IPs | `{ "mgm" = ["10.0.1.15"] }` |
| `iam_role_arns` | Map of IAM role ARNs | `{ "eks-master" = "arn:aws:iam::485950501937:role/rl-cis-uat-eks-master" }` |

> 📖 Full outputs documentation: [docs/06-OUTPUTS-GUIDE.md](docs/06-OUTPUTS-GUIDE.md)

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [docs/INDEX.md](docs/INDEX.md) | Full documentation index |
| [docs/00-OBJECTIVES.md](docs/00-OBJECTIVES.md) | Project goals and success criteria |
| [docs/01-PROJECT-OVERVIEW.md](docs/01-PROJECT-OVERVIEW.md) | Business context and use cases |
| [docs/02-ARCHITECTURE.md](docs/02-ARCHITECTURE.md) | Infrastructure design and topology |
| [docs/03-MODULES-OVERVIEW.md](docs/03-MODULES-OVERVIEW.md) | Module architecture strategy |
| [docs/04-MODULE-REFERENCE.md](docs/04-MODULE-REFERENCE.md) | Detailed module documentation |
| [docs/05-VARIABLES-GUIDE.md](docs/05-VARIABLES-GUIDE.md) | Input variables reference |
| [docs/06-OUTPUTS-GUIDE.md](docs/06-OUTPUTS-GUIDE.md) | Output values reference |
| [docs/07-QUICK-START.md](docs/07-QUICK-START.md) | Beginner-friendly tutorial |
| [docs/08-DEPLOYMENT-GUIDE.md](docs/08-DEPLOYMENT-GUIDE.md) | Detailed deployment procedures |
| [docs/09-STATE-MANAGEMENT.md](docs/09-STATE-MANAGEMENT.md) | Terraform state guide |
| [docs/10-TROUBLESHOOTING.md](docs/10-TROUBLESHOOTING.md) | Common issues and fixes |
| [docs/11-SECURITY-GUIDE.md](docs/11-SECURITY-GUIDE.md) | Security best practices |
| [docs/12-COST-OPTIMIZATION.md](docs/12-COST-OPTIMIZATION.md) | Cost management guide |
| [docs/13-BEST-PRACTICES.md](docs/13-BEST-PRACTICES.md) | Terraform and IaC best practices |
| [docs/14-RUNBOOK.md](docs/14-RUNBOOK.md) | Operational procedures |
| [docs/15-KNOWN-ISSUES.md](docs/15-KNOWN-ISSUES.md) | Known limitations |
| [docs/16-ROADMAP.md](docs/16-ROADMAP.md) | Future enhancements |

---

## 🔧 Prerequisites & Requirements

### Terraform Version
```hcl
terraform >= 1.12.0
provider "aws" ~> 5.0
```

### AWS CLI & Authentication
```bash
# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Configure credentials
aws configure
# OR use environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### Required IAM Permissions

The deploying user/role needs the following AWS managed policies (or equivalent):
- `AmazonVPCFullAccess`
- `AmazonEC2FullAccess`
- `AmazonEKSFullAccess`
- `AmazonECR_FullAccess`
- `IAMFullAccess`
- `AmazonS3FullAccess`
- `AmazonDynamoDBFullAccess`
- `AWSKeyManagementServicePowerUser`

### SSH Key Pair
```bash
# Create key pair in AWS
aws ec2 create-key-pair \
  --key-name learninggallery \
  --query 'KeyMaterial' \
  --output text > learninggallery.pem
chmod 400 learninggallery.pem
```

---

## 🎭 How to Use (By Scenario)

### Scenario 1: Deploy to UAT Environment
```bash
cd Project/LearningGallery/Infra-Code_UAT

# 1. Bootstrap state backend (first time only)
cd terraform-bootstrap && terraform init && terraform apply -auto-approve
cd ..

# 2. Update backend.tf with bucket name from bootstrap output
# 3. Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Scenario 2: Add a New EC2 Instance
```bash
# Edit data/infrastructure.csv — add a new row:
# tier,vpc_id,project,env,zone,role,count,instance_types,ami_id,...
app,core,cis,uat,ie,app,2,t3.medium,ami-03c3282f979a6a9b0,...

# Apply changes
terraform plan  # Review new resources
terraform apply
```

### Scenario 3: Add a New ECR Repository
```bash
# Edit data/ecr_repositories.csv — add a new row:
# cis,uat,newservice,IMMUTABLE,TRUE,30

terraform plan
terraform apply
```

### Scenario 4: Build and Deploy All Microservices
```bash
# In Jenkins:
# 1. Create a new pipeline job
# 2. Paste content from Apps-Code_UAT/jenkinsfiles/master-orchestrator
# 3. Trigger build
# Jenkins will build all 11 services, push to ECR, and update K8s YAMLs
```

### Scenario 5: Destroy Infrastructure
```bash
# CAUTION: This destroys ALL resources
terraform destroy

# For selective destruction:
terraform destroy -target=module.core_eks
```

---

## 🗄️ State Management

| Property | Value |
|----------|-------|
| **Backend Type** | AWS S3 (remote) |
| **State Bucket** | `st-cis-uat-tfstate-485950501937` |
| **State Key** | `core-infra/terraform.tfstate` |
| **Locking** | Native S3 lock file (`use_lockfile = true`) |
| **Encryption** | AES256 server-side encryption |
| **Region** | `ap-southeast-1` |

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "core-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
```

> 📖 Full state management guide: [docs/09-STATE-MANAGEMENT.md](docs/09-STATE-MANAGEMENT.md)

---

## 🔐 Security Considerations

| Security Control | Implementation |
|-----------------|----------------|
| **IMDSv2** | `http_tokens = required` on all EC2 instances |
| **KMS Encryption** | EKS secrets + ECR images encrypted at rest |
| **Immutable Tags** | ECR `image_tag_mutability = IMMUTABLE` |
| **OIDC/IRSA** | Pod-level Zero Trust IAM identity |
| **Non-root Containers** | `runAsNonRoot: true` on all K8s pods |
| **Read-only Filesystems** | `readOnlyRootFilesystem: true` on all containers |
| **Dropped Capabilities** | `capabilities.drop: [ALL]` on all containers |
| **State Encryption** | S3 state bucket AES256 encrypted |
| **Public Access Blocked** | S3 buckets block all public access |
| **Security Groups** | Least-privilege per-role SG rules |
| **NACLs** | Subnet-level stateless packet filtering |

> 📖 Full security guide: [docs/11-SECURITY-GUIDE.md](docs/11-SECURITY-GUIDE.md)

---

## 💰 Cost Considerations

### Estimated Monthly Cost (UAT Environment)

| Resource | Type | Estimated Cost/Month |
|----------|------|---------------------|
| EKS Cluster | Control plane | ~$73 |
| EC2 Node Group | 3x t3.large | ~$180 |
| EC2 Management | 1x t3.medium | ~$30 |
| ECR Storage | 11 repos | ~$5-15 |
| S3 State | Minimal | ~$1 |
| KMS Key | EKS encryption | ~$1 |
| NAT Gateway | Not deployed | $0 |
| **Total Estimate** | | **~$290-300/month** |

> ⚠️ Private EKS subnets currently have no NAT Gateway — nodes use public subnets for ECR pulls.

> 📖 Full cost guide: [docs/12-COST-OPTIMIZATION.md](docs/12-COST-OPTIMIZATION.md)

---

## 🔧 Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| `Error: No valid credential sources` | Run `aws configure` or set env vars |
| `Error acquiring the state lock` | Check S3 lock file, run `terraform force-unlock` |
| `InvalidParameterException: unsupported Kubernetes version` | Update `k8s_version` in `eks_clusters.csv` |
| `Error: Invalid for_each argument` | CSV has empty rows — remove blank lines |
| `Nodes not joining cluster` | Check node IAM role has `AmazonEKSWorkerNodePolicy` |
| `ECR push denied` | Run `aws ecr get-login-password` to refresh credentials |
| `kubectl: connection refused` | Re-run `aws eks update-kubeconfig` |

> 📖 Full troubleshooting guide: [docs/10-TROUBLESHOOTING.md](docs/10-TROUBLESHOOTING.md)

---

## 📋 Examples

### Minimal terraform.tfvars
```hcl
aws_region = "ap-southeast-1"
```

### Adding a New Subnet (subnets.csv)
```csv
id,vpc_id,cidr_block,az,is_public,role
web_az3,core,10.0.3.0/24,ap-southeast-1c,true,web
```

### Expected terraform plan output
```
Plan: 47 to add, 0 to change, 0 to destroy.

  + module.core_iam.aws_iam_role.role["ec2-profile"]
  + module.core_iam.aws_iam_role.role["eks-master"]
  + module.core_iam.aws_iam_role.role["eks-node"]
  + module.core_vpc["core"].aws_vpc.vpc
  + module.core_vpc["core"].aws_subnet.subnets["web_az1"]
  ...
  + module.core_eks["eks_main"].aws_eks_cluster.main
  + module.core_ecr.aws_ecr_repository.registry["adservice"]
  ...
```

> 📖 Full examples: [docs/examples/](docs/examples/)

---

## 🤝 Contributing

### Adding a New Module
```
1. Create directory: modules/<module_name>/
2. Create: main.tf, variables.tf, outputs.tf
3. Reference in: Infra-Code_UAT/main.tf
4. Add CSV data file if needed
5. Document in: docs/04-MODULE-REFERENCE.md
```

### Code Style
- Run `terraform fmt -recursive` before committing
- Use `terraform validate` to check syntax
- Follow naming convention: `<type>-<project>-<env>-<role>-<seq>`
- All resources must have `Name` tags

### Testing
```bash
terraform validate
terraform plan
trivy fs --scanners misconfig .
```

---

## 🛣️ Roadmap

- [ ] Add NAT Gateway for private subnet egress
- [ ] Implement AWS WAF for frontend LoadBalancer
- [ ] Add Prometheus/Grafana via Helm (Terraform)
- [ ] Add ArgoCD GitOps deployment module
- [ ] Multi-environment support (dev/staging/prod)
- [ ] Add AWS Certificate Manager for HTTPS
- [ ] Implement VPC Flow Logs
- [ ] Add Terraform test framework

> 📖 Full roadmap: [docs/16-ROADMAP.md](docs/16-ROADMAP.md)

---

## 📄 License & Contact

**License:** MIT — See [LICENSE](LICENSE)

| | |
|-|-|
| **Author** | Abu Talha |
| **GitHub** | [github.com/LearningGallery](https://github.com/LearningGallery) |
| **Email** | abutalha3005@gmail.com |
| **Project** | AWS-EKS-DevSecOps-Project |