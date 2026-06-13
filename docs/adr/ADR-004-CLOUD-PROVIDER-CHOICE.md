# ADR-004: Cloud Provider Choice

## Status
Accepted

## Context
We needed to select a cloud provider for this DevSecOps platform project.

## Decision
Use **Amazon Web Services (AWS)** in region `ap-southeast-1` (Singapore).

## Consequences

**Benefits:**
- AWS EKS is a mature, widely-adopted managed Kubernetes service
- Rich ecosystem: ECR, IAM, KMS, CloudWatch all natively integrated
- ap-southeast-1 is geographically relevant (Singapore-based project)
- AWS is the most common cloud provider in enterprise environments
- Extensive documentation and community support

**Trade-offs:**
- AWS-specific (not multi-cloud)
- Higher EKS cost vs self-managed Kubernetes
- Vendor lock-in for managed services

## Alternatives Considered

| Option | Reason Not Chosen |
|--------|------------------|
| Azure AKS | AWS more relevant to target audience |
| GCP GKE | AWS more widely used in Singapore market |
| Multi-cloud | Added complexity not justified for learning project |
| Self-managed K8s on EC2 | EKS provides better security and operational simplicity |
