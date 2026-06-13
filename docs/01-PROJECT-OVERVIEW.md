# 📋 Project Overview

---

## 1. Business Context

This project demonstrates a **complete DevSecOps delivery platform** suitable for a software engineering team building and deploying containerised microservices applications on AWS.

The infrastructure supports the full software delivery lifecycle:

```
Code → Build → Scan → Package → Push → Deploy → Monitor
 Git   Jenkins  Trivy  Docker   ECR    K8s/EKS  CloudWatch
```

---

## 2. Problem Statement

Modern cloud teams face several recurring infrastructure challenges:

| Problem | Impact |
|---------|--------|
| Manual infrastructure provisioning | Slow, error-prone, non-repeatable |
| Hardcoded configuration values | Brittle code that breaks on any change |
| No standard security baseline | Security vulnerabilities shipped to production |
| Manual image builds and pushes | Developer time wasted, human error introduced |
| No image traceability | Impossible to know which code version is running |
| State file conflicts | Team members overwrite each other's changes |

---

## 3. Solution Approach

This project solves these problems through four design patterns:

### Pattern 1: CSV-Driven Infrastructure Engine

Instead of hardcoding infrastructure in HCL, **all configuration lives in CSV files**:

```
vpcs.csv          → controls what VPCs exist
subnets.csv       → controls what subnets exist
sg_rules.csv      → controls all firewall rules
infrastructure.csv → controls what EC2 instances exist
eks_clusters.csv  → controls what EKS clusters exist
```

**Why this matters:** A non-Terraform engineer can add a subnet by editing a spreadsheet. No HCL knowledge required for common operations.

### Pattern 2: Zero Trust Security Baseline

Every resource applies security-by-default:

- EC2: IMDSv2 required, encrypted volumes, IAM instance profiles
- ECR: KMS encryption, immutable tags, scan-on-push
- EKS: KMS-encrypted secrets, OIDC/IRSA, full audit logging
- Containers: non-root, read-only filesystem, dropped Linux capabilities

### Pattern 3: GitOps CI/CD

The Jenkins master orchestrator implements a **GitOps pattern**:

```
1. Developer pushes code to GitHub
2. Jenkins builds Docker image
3. Image tagged with BUILD_NUMBER-GIT_SHA (e.g., 42-abc1234)
4. Image pushed to ECR
5. Jenkins updates kubernetes-files/service.yaml with new tag
6. Jenkins pushes YAML change back to GitHub
7. Git is the single source of truth for what's deployed
```

### Pattern 4: Modular, Composable Terraform

Six independent modules can be used in any combination:

```hcl
# Use just the VPC module
module "vpc" { source = "../../modules/vpc" ... }

# Or combine all modules
module "vpc"  { ... }
module "iam"  { ... }
module "ec2"  { ... }
module "eks"  { ... }
module "ecr"  { ... }
```

---

## 4. Target Audience

| Audience | How to Use This Project |
|----------|------------------------|
| **DevOps Engineers** | Reference architecture for AWS EKS deployments |
| **Cloud Architects** | CSV-driven IaC pattern for enterprise environments |
| **Security Engineers** | Zero Trust implementation patterns on Kubernetes |
| **Terraform Learners** | Study module design, for_each patterns, dynamic configurations |
| **AWS Learners** | End-to-end EKS, ECR, IAM, VPC integration |

---

## 5. Key Benefits

- **🔄 Repeatable** — Identical infrastructure on every `terraform apply`
- **📊 Data-Driven** — Change infrastructure by editing CSV, not code
- **🔒 Secure by Default** — Zero Trust applied at every layer
- **🐳 Container-Native** — ECR + EKS + Kubernetes manifests included
- **🚀 CI/CD Ready** — Jenkins pipelines for all 11 microservices
- **📦 Modular** — 6 reusable modules, composable for any project
- **👥 Team-Safe** — Remote state with locking prevents conflicts

---

## 6. Application: Google Online Boutique

The application layer deploys **Google's Online Boutique** — a cloud-native microservices demo e-commerce application:

| Service | Language | Purpose |
|---------|----------|---------|
| `frontend` | Go | Web UI, entry point |
| `adservice` | Java | Advertisement service |
| `cartservice` | C# | Shopping cart (uses Redis) |
| `checkoutservice` | Go | Order checkout orchestrator |
| `currencyservice` | Node.js | Currency conversion |
| `emailservice` | Python | Order confirmation emails |
| `paymentservice` | Node.js | Payment processing |
| `productcatalogservice` | Go | Product listings |
| `recommendationservice` | Python | Product recommendations |
| `shippingservice` | Go | Shipping quote/tracking |
| `loadgenerator` | Python/Locust | Synthetic traffic generator |
| `redis-cart` | Redis | In-memory cart storage |

All services communicate via **gRPC** (except frontend HTTP and Redis TCP).
