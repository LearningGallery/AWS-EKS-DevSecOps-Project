# 🛡️ AWS EKS DevSecOps Platform — Infrastructure as Code

[![Terraform](https://img.shields.io/badge/Terraform-1.12+-7B42BC?style=for-the-badge\&logo=terraform\&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=for-the-badge\&logo=amazonaws\&logoColor=white)](https://aws.amazon.com/)
[![EKS](https://img.shields.io/badge/Amazon_EKS-1.31-FF9900?style=for-the-badge\&logo=amazonaws\&logoColor=white)](https://aws.amazon.com/eks/)
[![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge\&logo=jenkins\&logoColor=white)](https://www.jenkins.io/)
[![DevSecOps](https://img.shields.io/badge/DevSecOps-Zero_Trust-00C853?style=for-the-badge\&logo=shield\&logoColor=white)](https://github.com/LearningGallery)
[![IaC](https://img.shields.io/badge/Infrastructure-as_Code-0064A5?style=for-the-badge\&logo=terraform\&logoColor=white)](https://github.com/LearningGallery)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Maintained](https://img.shields.io/badge/Maintained-Yes-green?style=for-the-badge)](https://github.com/LearningGallery)
[![Region](https://img.shields.io/badge/AWS_Region-ap--southeast--1-orange?style=for-the-badge\&logo=amazonaws)](https://aws.amazon.com/)

 > **Enterprise-grade AWS EKS DevSecOps platform built with Terraform IaC — deploying a production-ready Kubernetes cluster, CI/CD pipeline, and a fully containerised 11-service microservices application with Zero Trust security at every layer.**

---

## 📋 Table of Contents

- [Quick Summary](#-quick-summary)
- [Architecture Summary](#-architecture-summary)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Features \& Capabilities](#-features--capabilities)
- [Cloud Resources](#-cloud-resources)
- [Module Summary](#-module-summary)
- [Variable Reference](#-variable-reference)
- [Outputs Reference](#-outputs-reference)
- [Documentation](#-documentation)
- [Prerequisites](#-prerequisites--requirements)
- [How to Use](#-how-to-use-by-scenario)
- [State Management](#-state-management-overview)
- [Security](#-security-considerations)
- [Cost Considerations](#-cost-considerations)
- [Troubleshooting](#-troubleshooting-quick-links)
- [Examples](#-examples)
- [Contributing](#-contributing-guidelines)
- [Roadmap](#-roadmap)
- [License \& Contact](#-license--contact)

---

## 🎯 Quick Summary

| Attribute | Detail |
|-----------|--------|
| **Platform** | AWS (Amazon Web Services) |
| **Region** | `ap-southeast-1` (Singapore) |
| **IaC Tool** | Terraform `~> 1.12` |
| **Kubernetes** | Amazon EKS `v1.31` |
| **CI/CD** | Jenkins (self-hosted on EC2) |
| **Application** | Google Online Boutique (11-service microservices) |
| **Environment** | UAT (`uat`) |
| **Security Model** | Zero Trust — KMS, IMDSv2, IRSA, IMMUTABLE images |

### What does this project deploy?

This repository provisions a **complete DevSecOps cloud platform** on AWS:

1. **Networking Layer** — A VPC with public/private subnets, security groups, NACLs, and routing rules — all driven by CSV data files
2. **Identity Layer** — IAM roles for EC2, EKS control plane, and EKS worker nodes with least-privilege policies
3. **Compute Layer** — An EC2 management/tooling VM (`t3.medium`) bootstrapped with Jenkins, Docker, Trivy, kubectl, Helm, SonarQube, and all DevSecOps tooling
4. **Container Registry** — 11 ECR repositories (one per microservice) with KMS encryption, immutable tags, and lifecycle policies
5. **Kubernetes Layer** — An EKS cluster with KMS-encrypted secrets, OIDC/IRSA Zero Trust pod identity, CloudWatch logging, and managed node groups
6. **Application Layer** — 11 containerised microservices (Google Online Boutique) deployed to Kubernetes via GitOps-style Jenkins pipelines

### Who should use this?

- DevSecOps engineers learning AWS EKS deployment patterns
- Cloud architects evaluating enterprise IaC standards
- Developers building portfolio projects demonstrating end-to-end DevSecOps
- Teams wanting a reference implementation of CSV-driven Terraform infrastructure

---

## 🏗️ Architecture Summary

```

Internet
    │
    ▼
 ┌─────────────────────────────────────────────────────────────┐
 │                    AWS VPC (10.0.0.0/16)                    │
 │                                                             │
 │  ┌──────────────────┐    ┌──────────────────┐              │
 │  │  Public Subnet   │    │  Public Subnet   │              │
 │  │  web_az1         │    │  web_az2         │              │
 │  │  10.0.1.0/24     │    │  10.0.2.0/24     │              │
 │  │  (ap-se-1a)      │    │  (ap-se-1b)      │              │
 │  │                  │    │                  │              │
 │  │  ┌────────────┐  │    │                  │              │
 │  │  │  EC2 (MGM) │  │    │                  │              │
 │  │  │  Jenkins   │  │    │                  │              │
 │  │  │  SonarQube │  │    │                  │              │
 │  │  │  Trivy     │  │    │                  │              │
 │  │  └────────────┘  │    │                  │              │
 │  └──────────────────┘    └──────────────────┘              │
 │                                                             │
 │  ┌──────────────────┐    ┌──────────────────┐              │
 │  │  Private Subnet  │    │  Private Subnet  │              │
 │  │  eks_az1         │    │  eks_az2         │              │
 │  │  10.0.10.0/24    │    │  10.0.11.0/24    │              │
 │  │  (ap-se-1a)      │    │  (ap-se-1b)      │              │
 │  │                  │    │                  │              │
 │  │  ┌────────────┐  │    │  ┌────────────┐  │              │
 │  │  │ EKS Node   │  │    │  │ EKS Node   │  │              │
 │  │  │ t3.large   │  │    │  │ t3.large   │  │              │
 │  │  └────────────┘  │    │  └────────────┘  │              │
 │  └──────────────────┘    └──────────────────┘              │
 │                                                             │
 │           ┌─────────────────────────┐                      │
 │           │    EKS Control Plane    │                      │
 │           │    cis-uat-eks_main     │                      │
 │           │    K8s v1.31 + KMS      │                      │
 │           └─────────────────────────┘                      │
 └─────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
 ┌─────────────────┐      ┌──────────────────────┐
 │   Amazon ECR    │      │   S3 (Terraform       │
 │   11 Repos      │      │   State Backend)      │
 │   KMS Encrypted │      │   + DynamoDB Lock     │
 └─────────────────┘      └──────────────────────┘

```

📐 See detailed diagrams: [docs/diagrams/](docs/diagrams/)

---

## ⚡ Quick Start

### Prerequisites Checklist

- [ ] AWS CLI v2 installed and configured
- [ ] Terraform `>= 1.12` installed
- [ ] AWS IAM credentials with required permissions
- [ ] Git installed
- [ ] (Optional) `kubectl` for post-deploy cluster access

### Step 1 — Clone the Repository

```bash

git clone https://github.com/LearningGallery/AWS-EKS-DevSecOps-Project.git
cd AWS-EKS-DevSecOps-Project

```

### Step 2 — Configure AWS Credentials

```bash

aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region: ap-southeast-1

```

### Step 3 — Bootstrap State Backend (First-Time Only)

```bash

cd Project/LearningGallery/Infra-Code_UAT/terraform-bootstrap
terraform init
terraform plan
terraform apply -auto-approve
# Note the output bucket name — you'll need it in backend.tf

```

### Step 4 — Deploy Core Infrastructure

```bash

cd ../  # back to Infra-Code_UAT/
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

### Step 5 — Configure kubectl

```bash

aws eks update-kubeconfig \\
--region ap-southeast-1 \\
--name cis-uat-eks_main
kubectl get nodes

```

### Step 6 — Validate Deployment

```bash

# Check EC2 Instance
aws ec2 describe-instances --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01"

# Check EKS Cluster
aws eks describe-cluster --name cis-uat-eks_main --region ap-southeast-1

# Check ECR Repos
aws ecr describe-repositories --region ap-southeast-1

```

📖 Full guide: [docs/07-QUICK-START.md](docs/07-QUICK-START.md)

---

## 📁 Project Structure

```

# AWS-EKS-DevSecOps-Project/
│
├── README.md                              # This file
├── .gitignore                             # Excludes secrets, state, and temp files
│
├── modules/                               # ♻️ Reusable Terraform modules
│   ├── ec2/                               # EC2 instance provisioning
|   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── ecr/                               # ECR container registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── eks/                               # EKS cluster + node groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── output.tf
│   │   └── eks-jenkinsfile                # EKS-specific Jenkinsfile
│   ├── iam/                               # IAM roles, policies, profiles
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── s3/                                # S3 bucket management
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   └── vpc/                               # VPC, subnets, SGs, NACLs, routes
│       ├── main.tf
|       ├── variables.tf
│       └── output.tf
│
└── Project/
   └── LearningGallery/
       ├── Infra-Code_UAT/                # 🚀 Root Terraform configuration
       │   ├── main.tf                    # CSV-driven infrastructure engine
       │   ├── provider.tf                # AWS provider + Terraform config
       │   ├── backend.tf                 # S3 remote state backend
       │   ├── variables.tf               # Root variables
       │   ├── output.tf                  # Root outputs (currently commented)
       │   │
       │   ├── data/                      # 📊 CSV data engine files
       │   │   ├── vpcs.csv               # VPC definitions
       │   │   ├── subnets.csv            # Subnet layout
       │   │   ├── sg_rules.csv           # Security group rules
       │   │   ├── nacl_rules.csv         # Network ACL rules
       │   │   ├── route_rules.csv        # Routing configuration
       │   │   ├── iam_roles.csv          # IAM role definitions
       │   │   ├── infrastructure.csv     # EC2 instance definitions
       │   │   ├── ecr_repositories.csv   # ECR repo definitions
       │   │   ├── eks_clusters.csv       # EKS cluster config
       │   │   ├── eks_node_groups.csv    # EKS node group config
       │   │   └── bootstrap_backends.csv # Bootstrap S3/DynamoDB config
       │   │
       │   ├── policies/                  # IAM custom policy JSON files
       │   │   ├── eks_custom_policy.json
       │   │   └── eks_autoscaler_policy.json
       │   │
       │   ├── scripts/                   # EC2 user data bootstrap scripts
       │   │   ├── updated_install-tools.sh  # Production bootstrap script
       │   │   └── install-tools.sh          # Legacy bootstrap script
       │   │
       │   └── terraform-bootstrap/       # 🔑 One-time state backend setup
       │       ├── main.tf
       │       ├── variables.tf
       │       ├── outputs.tf
       │       └── terraform.tfstate
       │
       └── Apps-Code_UAT/                 # 🐳 Application layer
           ├── kubernetes-files/          # K8s YAML manifests (11 services)
           │   ├── adservice.yaml
           │   ├── cartservice.yaml
           │   ├── checkoutservice.yaml
           │   ├── currencyservice.yaml
           │   ├── emailservice.yaml
           │   ├── frontend.yaml          # Includes LoadBalancer service
           │   ├── loadgenerator.yaml
           │   ├── paymentservice.yaml
           │   ├── productcatalogservice.yaml
           │   ├── recommendationservice.yaml
           │   ├── redis-cart.yaml
           │   └── shippingservice.yaml
           │
           └── jenkinsfiles/              # CI/CD pipeline definitions
               ├── master-orchestrator    # Builds all 11 services in sequence
               ├── adservice
               ├── cartservice
               ├── checkoutservice
               ├── currencyservice
               ├── emailservice
               ├── frontend
               ├── loadgenerator
               ├── paymentservice
               ├── productcatalogservice
               ├── recommendationservice
               └── shippingservice

```

---

## ✨ Features \& Capabilities

### 🌐 Networking

- VPC with configurable CIDR (`10.0.0.0/16`)
- Multi-AZ public subnets for management workloads
- Multi-AZ private subnets for EKS worker nodes
- Internet Gateway with dynamic route rules
- Per-tier Network ACLs with granular ingress/egress rules
- Per-tier Security Groups with fine-grained rule management

### 🔐 Identity \& Security

- IAM roles for EC2, EKS control plane, and EKS worker nodes
- KMS-encrypted Kubernetes secrets (envelope encryption)
- IMDSv2 enforced on all EC2 instances (`http_tokens = required`)
- EKS OIDC provider for IRSA (pod-level Zero Trust identity)
- Immutable ECR image tags (prevents tag overwriting)
- Scan-on-push enabled for all container images
- Read-only root filesystem on all Kubernetes containers
- Non-root containers enforced (`runAsNonRoot: true`)
- All Linux capabilities dropped (`drop: [ALL]`)

### ⚙️ Compute \& Container Platform

- Self-hosted EC2 management VM (Jenkins, SonarQube, Trivy, Vault)
- Amazon EKS `v1.31` with managed node groups (`t3.large`, ON_DEMAND)
- Node auto-scaling (min: 2, max: 10, desired: 3)
- EKS CloudWatch logging (api, audit, authenticator, controllerManager, scheduler)

# ### 📦 Container Registry

- 11 ECR repositories (one per microservice)
- KMS encryption on all repositories
- Lifecycle policies (retain last 30 images)
- Automatic scan on every push

# ### 🔄 CI/CD Pipeline

- Master orchestrator pipeline builds all 11 services sequentially
- Git SHA-tagged images for full traceability (`BUILD_NUMBER-GIT_SHA`)
- Automatic Kubernetes YAML updates via `sed` + Git push
- Trivy IaC security scanning integrated into EKS pipeline
- Workspace cleanup after every build

### 🗄️ State Management

- Remote S3 backend (`st-cis-uat-tfstate-485950501937`)
- State locking via S3 native locking (`use_lockfile = true`)
- AES256 encryption at rest
- Bootstrap module for one-time backend provisioning

---

## ☁️ Cloud Resources

| Module | Resources Created | Count | Purpose |
|--------|------------------|-------|---------|
| `vpc` | VPC | 1 | Core network isolation |
| `vpc` | Subnets | 4 | 2x public (web), 2x private (eks) |
| `vpc` | Internet Gateway | 1 | Public internet access |
| `vpc` | Route Tables | 3 | 1 public + 2 private |
| `vpc` | Security Groups | 2+ | Per-role traffic control |
| `vpc` | Network ACLs | 2 | Subnet-level packet filtering |
| `iam` | IAM Roles | 3 | ec2-profile, eks-master, eks-node |
| `iam` | IAM Policies | 2 | Custom EKS + Autoscaler policies |
| `iam` | Instance Profiles | 2 | EC2 + EKS node profiles |
| `ec2` | EC2 Instances | 1 | Management VM (t3.medium) |
| `ec2` | EBS Volumes | 1 | 30GB gp3 encrypted root volume |
| `ecr` | ECR Repositories | 11 | One per microservice |
| `ecr` | Lifecycle Policies | 11 | Image retention management |
| `eks` | EKS Cluster | 1 | Kubernetes control plane |
| `eks` | KMS Key | 1 | K8s secret encryption |
| `eks` | Node Groups | 1 | Worker node pool (t3.large) |
| `main` | OIDC Providers | 1 | IRSA Zero Trust pod identity |
| `main` | EKS Access Entry | 1 | EC2 admin access to cluster |
| `bootstrap` | S3 Bucket | 1 | Terraform state storage |
| `bootstrap` | DynamoDB Table | 1 | State locking (legacy) |

---

## 📦 Module Summary

| Module | Path | Purpose | Key Resources | Outputs |
|--------|------|---------|---------------|---------|
| `vpc` | `modules/vpc` | Full VPC stack | VPC, subnets, SGs, NACLs, routes | `vpc_id`, `subnet_ids`, `sg_ids` |
| `iam` | `modules/iam` | IAM roles \& profiles | Roles, policies, instance profiles | `role_arns`, `instance_profile_names` |
| `ec2` | `modules/ec2` | EC2 instances | EC2 instances, EBS volumes | `instance_ids`, `private_ips`, `arns` |
| `ecr` | `modules/ecr` | Container registries | ECR repos, lifecycle policies | `repository_urls`, `repository_arns` |
| `eks` | `modules/eks` | Kubernetes cluster | EKS cluster, KMS key, node groups, SG rules | `cluster_endpoint`, `cluster_name`, `oidc_issuer_url` |
| `s3` | `modules/s3` | Object storage | S3 buckets, versioning, encryption | `bucket_names`, `bucket_arns` |

---

# ## 🔧 Variable Reference (Summary)

# Variables are primarily managed through **CSV data files** rather than traditional `terraform.tfvars`:

| Data File | Controls | Key Fields |
|-----------|----------|------------|
| `data/vpcs.csv` | VPC creation | `vpc_id`, `cidr_block`, `network_zone` |
| `data/subnets.csv` | Subnet layout | `cidr_block`, `az`, `is_public`, `role` |
| `data/sg_rules.csv` | Firewall rules | `sg_role`, `type`, `from_port`, `to_port` |
| `data/nacl_rules.csv` | NACL rules | `rule_no`, `action`, `cidr_block` |
| `data/iam_roles.csv` | IAM configuration | `trusted_service`, `managed_policies` |
| `data/infrastructure.csv` | EC2 instances | `instance_types`, `ami_id`, `userdata_file` |
| `data/ecr_repositories.csv` | ECR repos | `service_name`, `image_mutability` |
| `data/eks_clusters.csv` | EKS clusters | `k8s_version`, `subnet_ids` |
| `data/eks_node_groups.csv` | Node groups | `instance_types`, `min_size`, `max_size` |

📖 Full guide: [docs/05-VARIABLES-GUIDE.md](docs/05-VARIABLES-GUIDE.md)

---

# ## 📤 Outputs Reference

| Output | Module | Description | Example Value |
|--------|--------|-------------|---------------|
| `eks_cluster_name` | `core_eks` | EKS cluster name | `cis-uat-eks_main` |
| `eks_cluster_endpoint` | `core_eks` | K8s API endpoint | `https://XXXX.gr7.ap-southeast-1.eks.amazonaws.com` |
| `oidc_issuer_url` | `core_eks` | OIDC URL for IRSA | `https://oidc.eks.ap-southeast-1.amazonaws.com/id/XXXX` |
| `ecr_repository_urls` | `core_ecr` | Map of ECR URLs | `{ "frontend" = "485950501937.dkr.ecr..." }` |
| `vpc_id` | `core_vpc` | VPC ID | `vpc-0a1b2c3d4e` |
| `subnet_ids` | `core_vpc` | Map of subnet IDs | `{ "web_az1" = "subnet-XXXX" }` |
| `sg_ids` | `core_vpc` | Map of SG IDs | `{ "sg-web" = "sg-XXXX" }` |
| `role_arns` | `core_iam` | Map of IAM ARNs | `{ "eks-master" = "arn:aws:iam::..." }` |
| `instance_ids` | `ec2_infrastructure` | EC2 instance IDs | `["i-XXXX"]` |
| `state_bucket_names` | `bootstrap` | State bucket names | `{ "core_uat" = "st-cis-uat-tfstate-..." }` |

📖 Full guide: [docs/06-OUTPUTS-GUIDE.md](docs/06-OUTPUTS-GUIDE.md)

---

# ## 📚 Documentation

| Document | Description |
|----------|-------------|
| [docs/INDEX.md](docs/INDEX.md) | Full documentation index |
| [docs/00-OBJECTIVES.md](docs/00-OBJECTIVES.md) | Project goals and success criteria |
| [docs/01-PROJECT-OVERVIEW.md](docs/01-PROJECT-OVERVIEW.md) | Business context and problem statement |
| [docs/02-ARCHITECTURE.md](docs/02-ARCHITECTURE.md) | Infrastructure design and topology |
| [docs/03-MODULES-OVERVIEW.md](docs/03-MODULES-OVERVIEW.md) | Module architecture strategy |
| [docs/04-MODULE-REFERENCE.md](docs/04-MODULE-REFERENCE.md) | Detailed per-module documentation |
| [docs/05-VARIABLES-GUIDE.md](docs/05-VARIABLES-GUIDE.md) | All input variables reference |
| [docs/06-OUTPUTS-GUIDE.md](docs/06-OUTPUTS-GUIDE.md) | All output values reference |
| [docs/07-QUICK-START.md](docs/07-QUICK-START.md) | Step-by-step deployment tutorial |
| [docs/08-DEPLOYMENT-GUIDE.md](docs/08-DEPLOYMENT-GUIDE.md) | Detailed deployment procedures |
| [docs/09-STATE-MANAGEMENT.md](docs/09-STATE-MANAGEMENT.md) | Terraform state guide |
| [docs/10-TROUBLESHOOTING.md](docs/10-TROUBLESHOOTING.md) | Common issues and solutions |
| [docs/11-SECURITY-GUIDE.md](docs/11-SECURITY-GUIDE.md) | Security best practices |
| [docs/12-COST-OPTIMIZATION.md](docs/12-
