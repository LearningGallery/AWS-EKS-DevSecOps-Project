# 🎯 Project Objectives

---

## 1. Project Goals

This project was built to achieve the following goals:

### 1.1 Technical Goals

| Goal | Description | Status |
|------|-------------|--------|
| **Reproducible Infrastructure** | Any engineer can deploy identical infrastructure from the same codebase | ✅ Achieved |
| **CSV-Driven IaC** | Infrastructure changes require only CSV edits, not HCL code changes | ✅ Achieved |
| **Zero Trust Security** | Every layer implements security-by-default (KMS, IMDSv2, IRSA, immutable tags) | ✅ Achieved |
| **Containerised Application** | 11-service microservices application deployed on Kubernetes | ✅ Achieved |
| **Automated CI/CD** | Jenkins pipelines build, scan, push, and deploy all services automatically | ✅ Achieved |
| **Remote State** | Team-safe Terraform state with S3 backend and locking | ✅ Achieved |
| **Reusable Modules** | 6 independent, composable Terraform modules | ✅ Achieved |

### 1.2 Learning Outcomes

By studying this project, you will understand:

- How to design a **CSV-driven Terraform data engine** for large-scale, table-driven infrastructure
- How to implement **Zero Trust security** on AWS (KMS, IMDSv2, OIDC, immutable ECR)
- How to deploy and configure **Amazon EKS** with full control plane logging
- How to implement **IRSA (IAM Roles for Service Accounts)** for pod-level identity
- How to build a **GitOps CI/CD pipeline** with Jenkins that auto-updates Kubernetes manifests
- How to structure a **multi-module Terraform project** with proper dependency management
- How to implement **defense-in-depth networking** with VPCs, Security Groups, and NACLs
- How to bootstrap and manage **remote Terraform state** with S3

---

## 2. Infrastructure Objectives

### 2.1 Networking
- Deploy a production-grade VPC with public and private subnet tiers
- Implement multi-AZ redundancy for high availability
- Apply Security Groups and NACLs for defense-in-depth
- Route public traffic via Internet Gateway

### 2.2 Compute
- Provision a management EC2 instance with all DevSecOps tooling pre-installed
- Deploy a scalable EKS managed node group (2-10 nodes, t3.large)

### 2.3 Container Platform
- Deploy Amazon EKS v1.31 with KMS-encrypted Kubernetes secrets
- Enable full control plane logging to CloudWatch
- Configure OIDC provider for IRSA (pod-level Zero Trust identity)
- Provision 11 ECR repositories with immutable tags and lifecycle policies

### 2.4 CI/CD
- Implement per-service Jenkins pipelines with Git SHA tagging
- Implement a master orchestrator pipeline to build all services in sequence
- Integrate Trivy IaC security scanning into the EKS pipeline
- Implement GitOps: automatic Kubernetes YAML updates on every build

---

## 3. Scope

### In Scope ✅

- VPC, subnets, security groups, NACLs, route tables
- EC2 instance with bootstrap tooling script
- EKS cluster and managed node groups
- ECR repositories for all 11 microservices
- IAM roles, policies, and instance profiles
- S3 remote state backend (bootstrap)
- Jenkins CI/CD pipelines (Jenkinsfiles)
- Kubernetes deployment manifests (11 services + Redis)
- OIDC provider for IRSA

### Out of Scope ❌

- NAT Gateway (private subnets have no outbound internet via NAT)
- AWS WAF / CloudFront
- AWS Certificate Manager / HTTPS/TLS termination
- Route53 DNS
- VPC Flow Logs
- AWS Config / CloudTrail
- Helm charts (ArgoCD, Prometheus — included in bootstrap script but not Terraform-managed)
- Production multi-region setup
- AWS Secrets Manager / Parameter Store integration

---

## 4. Success Criteria

The project is considered successful when:

- [ ] `terraform apply` completes without errors
- [ ] EKS cluster is ACTIVE and nodes are in READY state
- [ ] All 11 ECR repositories are created with correct settings
- [ ] Management EC2 instance is accessible and Jenkins is running on port 8080
- [ ] `kubectl get nodes` returns worker nodes
- [ ] Jenkins master orchestrator pipeline builds and pushes all 11 images to ECR
- [ ] All 11 microservices are running in the EKS cluster
- [ ] Frontend is accessible via the LoadBalancer service external IP
- [ ] Terraform state is stored in S3 and locked via lock file

---

## 5. Compliance Considerations

| Control | Implementation |
|---------|---------------|
| Encryption at rest | KMS for EKS secrets, AES256 for S3 and ECR |
| Encryption in transit | All EKS API calls over HTTPS |
| Access control | IAM roles with least-privilege policies |
| Audit logging | EKS control plane logs: api, audit, authenticator |
| Image integrity | Immutable ECR tags prevent tag reuse |
| Container security | Non-root, read-only filesystem, dropped capabilities |
