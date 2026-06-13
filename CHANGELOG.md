# 📝 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2025

### Added

#### Infrastructure
- VPC module with CSV-driven subnet, security group, NACL, and route configuration
- IAM module supporting multiple roles with semicolon-separated policy lists
- EC2 module with IMDSv2 enforcement, encrypted EBS, and user data support
- EKS module with KMS-encrypted secrets, OIDC provider, and managed node groups
- ECR module with KMS encryption, immutable tags, scan-on-push, and lifecycle policies
- S3 module with versioning, AES256 encryption, and public access blocking
- Bootstrap module for one-time S3 + DynamoDB state backend provisioning

#### Security
- IMDSv2 enforced on all EC2 instances (`http_tokens = required`)
- KMS envelope encryption for Kubernetes secrets
- Immutable ECR image tags (`image_tag_mutability = IMMUTABLE`)
- ECR scan-on-push enabled for all 11 repositories
- OIDC provider for IRSA (pod-level Zero Trust identity)
- EKS access entries replacing legacy ConfigMap-based authentication
- Full EKS control plane logging (api, audit, authenticator, controllerManager, scheduler)
- S3 state bucket with public access blocking and AES256 encryption
- Non-root containers with read-only filesystems and dropped capabilities

#### CI/CD
- Jenkins master orchestrator pipeline (builds all 11 services sequentially)
- Per-service Jenkinsfiles for granular pipeline control
- `BUILD_NUMBER-GIT_SHA` image tagging for full build traceability
- GitOps pattern: Jenkins auto-updates Kubernetes YAML after successful build
- Trivy IaC security scanning integrated into EKS Terraform pipeline
- Workspace cleanup post every build

#### Application
- 11 ECR repositories (one per microservice)
- 12 Kubernetes deployment manifests (11 services + redis-cart)
- All containers with security baseline (non-root, read-only FS, dropped capabilities)
- Resource requests and limits on all containers
- gRPC health probes on all backend services
- HTTP health probes on frontend service
- LoadBalancer service for frontend external access

#### State Management
- S3 remote backend with native state locking (`use_lockfile = true`)
- Bootstrap module for one-time backend provisioning
- AES256 encryption for state at rest

#### Documentation
- Complete README with badges, architecture, and quick start
- 17 documentation files covering all aspects
- 6 Architecture Decision Records (ADRs)
- 4 Mermaid diagrams (topology, dependencies, flow, data)
- Examples for basic, advanced, and multi-environment deployments
- All CSV column documentation with types and examples

### Technical Specifications

| Component | Version/Specification |
|-----------|----------------------|
| Terraform | >= 1.12.0 |
| AWS Provider | ~> 5.0 |
| Kubernetes | 1.31 |
| EKS Node Type | t3.large (ON_DEMAND) |
| Management EC2 | t3.medium |
| VPC CIDR | 10.0.0.0/16 |
| AWS Region | ap-southeast-1 |

---

## [Unreleased]

### Planned for v1.1
- NAT Gateway for private subnet egress
- VPC Flow Logs
- Restrict administrative SG rules from 0.0.0.0/0

### Planned for v1.2
- ArgoCD GitOps module via Helm
- Remove manual kubectl deployment steps

### Planned for v1.3
- Prometheus + Grafana observability stack
- CloudWatch Container Insights
```

---

## `LICENSE`

```
MIT License

Copyright (c) 2025 Abu Talha (LearningGallery)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
