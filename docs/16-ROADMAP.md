# 🛣️ Roadmap

---

## Current Version: v1.0 (UAT)

The current version delivers a complete, working DevSecOps platform with:
- VPC networking, IAM, EC2, ECR, and EKS infrastructure
- CI/CD pipelines for 11 microservices
- Zero Trust security baseline
- Remote state management

---

## Planned Enhancements

### 🔜 v1.1 — Network Hardening

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| NAT Gateway | High | Medium | Enable private subnet internet egress |
| VPC Flow Logs | High | Low | Network traffic logging for audit |
| Restrict SG CIDRs | High | Low | Replace 0.0.0.0/0 with specific IPs |
| Move EKS nodes to private subnets | High | Low | True private Kubernetes nodes |
| EKS private endpoint only | Medium | Low | Disable public EKS API endpoint |

**Implementation plan:**
```csv
# data/route_rules.csv — add NAT route:
core,eks,0.0.0.0/0,nat

# data/sg_rules.csv — restrict admin ports:
core,web,ingress,22,22,tcp,cidr,10.0.0.0/8,Allow SSH from internal
```

---

### 🔜 v1.2 — GitOps with ArgoCD

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| ArgoCD Terraform module | High | High | Deploy ArgoCD via Helm + Terraform |
| ArgoCD Application manifests | High | Medium | Auto-sync K8s manifests from Git |
| Remove manual kubectl apply | Medium | Low | ArgoCD replaces manual deployment |
| Multi-cluster ArgoCD | Low | High | Manage multiple EKS clusters |

**Proposed Terraform:**
```hcl
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true
}
```

---

### 🔜 v1.3 — Observability Stack

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| Prometheus via Helm | High | Medium | Metrics collection |
| Grafana via Helm | High | Medium | Metrics visualisation |
| AlertManager | Medium | Medium | Alert routing |
| AWS CloudWatch Container Insights | Medium | Low | Native AWS monitoring |
| Loki for log aggregation | Low | High | Centralised logging |

**Proposed Terraform:**
```hcl
resource "helm_release" "prometheus_stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
}
```

---

### 🔜 v1.4 — Security Enhancements

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| AWS WAF on LoadBalancer | High | Medium | Web application firewall |
| AWS Certificate Manager | High | Medium | HTTPS/TLS termination |
| AWS Secrets Manager integration | High | High | Proper secret management |
| OPA/Gatekeeper policies | Medium | High | Kubernetes policy enforcement |
| AWS GuardDuty | Medium | Low | Threat detection |
| AWS Security Hub | Medium | Low | Security posture management |
| VPC Endpoint for ECR | Medium | Medium | Private ECR access (no internet) |

---

### 🔜 v1.5 — Multi-Environment Support

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| dev environment | Medium | Low | Smaller instance types, single AZ |
| staging environment | Medium | Low | Mirror of UAT |
| production environment | High | Medium | Multi-AZ, larger instances, strict SGs |
| Terraform workspaces | Low | Medium | Single codebase, multiple environments |
| Environment-specific tfvars | Medium | Low | Per-environment variable overrides |

**Proposed directory structure:**
```
environments/
├── dev/
│   ├── data/         # Dev-specific CSV files
│   └── backend.tf
├── uat/
│   ├── data/         # UAT CSV files (current)
│   └── backend.tf
└── prod/
    ├── data/         # Prod CSV files
    └── backend.tf
```

---

### 🔜 v1.6 — Infrastructure Improvements

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| Cluster Autoscaler via Helm | High | Medium | Automatic node scaling |
| AWS Load Balancer Controller | High | Medium | Replace classic ELB with ALB |
| EKS Managed Add-ons | Medium | Low | CoreDNS, kube-proxy, VPC CNI |
| SPOT instance mixed strategy | Medium | Low | ON_DEMAND base + SPOT burst |
| S3 module integration | Low | Low | Wire up existing S3 module |
| Transit Gateway module | Low | High | Multi-VPC connectivity |

---

### 🔜 v2.0 — Production-Ready Platform

| Enhancement | Priority | Effort | Description |
|-------------|----------|--------|-------------|
| Disaster Recovery runbook | High | Medium | Cross-region failover procedures |
| AWS Backup integration | High | Medium | Automated backup policies |
| SLA monitoring | Medium | High | Uptime and performance tracking |
| Cost anomaly detection | Medium | Low | Automated cost alerts |
| Terraform Cloud/Enterprise | Low | High | Remote execution and team features |
| Terratest integration | Medium | High | Automated infrastructure testing |

---

## Deprecation Schedule

| Feature | Deprecation | Replacement | Timeline |
|---------|-------------|-------------|----------|
| `install-tools.sh` (legacy) | Deprecated | `updated_install-tools.sh` | Remove in v1.2 |
| `ecr_repos.csv` (unused) | Deprecated | `ecr_repositories.csv` | Remove in v1.1 |
| `s3_buckets.csv` (empty) | Pending | Active S3 module integration | v1.6 |
| Local EKS subnet deployment | Deprecated | Private subnet + NAT | v1.1 |

---

## Version Upgrade Path

```
v1.0 (Current)
  └── Terraform ~> 5.0 AWS Provider
  └── Kubernetes 1.31
  └── Local kubeconfig management

v1.1
  └── Network hardening
  └── Kubernetes 1.32 (when available)

v1.2
  └── ArgoCD GitOps
  └── Remove manual kubectl steps

v1.3
  └── Prometheus + Grafana stack
  └── Full observability

v2.0
  └── Production-grade platform
  └── Full DR capability
  └── Automated testing
```