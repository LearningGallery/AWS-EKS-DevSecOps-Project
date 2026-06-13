# 🔐 Security Guide

---

## 1. Security Architecture Overview

This project implements **Zero Trust Security** — the principle that nothing is trusted by default, and every access must be explicitly verified.

```
Zero Trust Layers:
├── Network Layer  → VPC, Security Groups, NACLs
├── Identity Layer → IAM roles, OIDC/IRSA
├── Compute Layer  → IMDSv2, encrypted volumes
├── Container Layer → Non-root, read-only filesystem
├── Registry Layer  → KMS encryption, immutable tags
├── Data Layer      → KMS-encrypted K8s secrets
└── Pipeline Layer  → Trivy scanning, Git SHA tags
```

---

## 2. Network Security

### Security Groups (Stateful)

Security Groups are **stateful** — return traffic is automatically allowed:

```hcl
# Current web SG ingress rules (from sg_rules.csv):
Port 22   (SSH)    - 0.0.0.0/0  ← Restrict to your IP in production!
Port 80   (HTTP)   - 0.0.0.0/0
Port 443  (HTTPS)  - 0.0.0.0/0
Port 8080 (Jenkins)- 0.0.0.0/0  ← Restrict to your IP in production!
Port 9000 (Sonar)  - 0.0.0.0/0  ← Restrict to your IP in production!
Port 9090 (Prom)   - 0.0.0.0/0
```

**Production hardening — update sg_rules.csv:**
```csv
# Replace 0.0.0.0/0 with your office IP:
core,web,ingress,22,22
| `ec2-profile` | AdministratorAccess + custom EKS policy | Management VM needs broad access for DevOps operations |

> ⚠️ **Production Note:** The `ec2-profile` role has `AdministratorAccess`. This is acceptable for a learning/UAT environment but should be scoped down for production. Replace with specific service permissions.

### OIDC / IRSA (Zero Trust Pod Identity)

IRSA (IAM Roles for Service Accounts) allows **individual Kubernetes pods** to assume IAM roles — no shared credentials on nodes:

```hcl
# How IRSA works in this project:

# Step 1: EKS creates OIDC issuer URL
oidc_issuer_url = "https://oidc.eks.ap-southeast-1.amazonaws.com/id/XXXX"

# Step 2: Terraform reads TLS certificate from OIDC endpoint
data "tls_certificate" "eks" {
  url = each.value.oidc_issuer_url
}

# Step 3: Creates OIDC identity provider in IAM
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[each.key].certificates[0].sha1_fingerprint]
  url             = each.value.oidc_issuer_url
}

# Step 4: Create service-account-scoped IAM role (example):
resource "aws_iam_role" "s3_reader" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${aws_iam_openid_connect_provider.eks.url}:sub" = "system:serviceaccount:default:my-service-account"
        }
      }
    }]
  })
}
```

### EKS Access Entry

```hcl
# EC2 management instance gets cluster admin access
resource "aws_eks_access_entry" "ec2_profile_access" {
  cluster_name  = module.core_eks["eks_main"].cluster_name
  principal_arn = module.core_iam.role_arns["ec2-profile"]
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ec2_profile_admin" {
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope { type = "cluster" }
}
```

---

## 4. Compute Security

### IMDSv2 Enforcement

All EC2 instances require **token-based metadata access** (IMDSv2):

```hcl
metadata_options {
  http_endpoint = "enabled"
  http_tokens   = "required"  # Forces IMDSv2 — prevents SSRF attacks
}
```

**Why this matters:** IMDSv1 allowed any process on the instance to query `http://169.254.169.254/latest/meta-data/iam/security-credentials/` and steal IAM credentials. IMDSv2 requires a signed token, blocking this attack.

### Encrypted EBS Volumes

```hcl
root_block_device {
  encrypted   = true        # AES-256 encryption
  volume_type = "gp3"       # Latest generation
  volume_size = 30          # GB
}
```

### AMI Lifecycle

```hcl
lifecycle {
  ignore_changes = [ami]    # Prevents drift when AMI is updated
}
```

---

## 5. Container Security

All 11 Kubernetes deployments implement the same security baseline:

### Pod Security Context

```yaml
securityContext:
  fsGroup: 1000
  runAsGroup: 1000
  runAsNonRoot: true    # Never run as root
  runAsUser: 1000       # Specific non-root UID
```

### Container Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false   # Cannot gain more privileges
  privileged: false                  # Not a privileged container
  readOnlyRootFilesystem: true       # Cannot write to filesystem
  capabilities:
    drop:
      - ALL                          # Drop ALL Linux capabilities
```

### Resource Limits

All containers have explicit CPU and memory limits:

```yaml
resources:
  requests:
    cpu: 100m       # Guaranteed CPU
    memory: 64Mi    # Guaranteed memory
  limits:
    cpu: 200m       # Maximum CPU
    memory: 128Mi   # Maximum memory (OOM killed if exceeded)
```

### Health Probes

All containers implement readiness and liveness probes:

```yaml
readinessProbe:
  grpc:
    port: 9555              # gRPC health check
  initialDelaySeconds: 20
  periodSeconds: 15

livenessProbe:
  grpc:
    port: 9555
  initialDelaySeconds: 20
  periodSeconds: 15
```

---

## 6. Container Registry Security

### ECR Security Features

```hcl
# Immutable tags — prevents overwriting published images
image_tag_mutability = "IMMUTABLE"

# KMS encryption — all images encrypted at rest
encryption_configuration {
  encryption_type = "KMS"   # AWS-managed KMS key
}

# Scan every push — detect CVEs automatically
image_scanning_configuration {
  scan_on_push = true
}
```

### Image Tagging Strategy

```
Format: <BUILD_NUMBER>-<GIT_SHA>
Example: 42-abc1234

Benefits:
✅ Traceability — exact code version known from tag
✅ Immutability — unique tag per build (never reused)
✅ Rollback — previous tags preserved (last 30 kept)
✅ Audit — can map running image to exact Git commit
```

---

## 7. Secrets Management

### Current Approach

| Secret Type | Storage | Access Method |
|------------|---------|---------------|
| AWS credentials (local) | `~/.aws/credentials` | AWS SDK auto-discovery |
| Jenkins Git PAT | Jenkins Credentials Store | `withCredentials()` block |
| Bootstrap state | Local tfstate (bootstrap only) | Not in Git |
| EKS secrets | KMS-encrypted in etcd | Kubernetes API |

### Sensitive Variables in Terraform

```hcl
# Mark outputs as sensitive to prevent console display
output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.main.certificate_authority[0].data
  sensitive = true
}
```

### What Is NOT In Git

Enforced via `.gitignore`:

```gitignore
*.tfstate          # Never commit state files
*.tfstate.*        # Never commit state backups
*.tfvars           # Never commit variable values with secrets
*.tfvars.json      # Never commit JSON variable files
secrets/           # Never commit secrets directory
*.gpg              # Never commit encrypted files
.env               # Never commit environment files
```

---

## 8. Security Scanning

### Trivy IaC Scanning (EKS Pipeline)

```groovy
stage('Security Scan (Trivy IaC)') {
  steps {
    sh 'trivy fs --scanners misconfig --severity CRITICAL,HIGH --exit-code 1 .'
    // --exit-code 1: Pipeline FAILS if CRITICAL or HIGH misconfigurations found
  }
}
```

### SonarQube Integration

SonarQube is deployed on the management EC2 at port 9000:

```bash
# Access SonarQube
http://<EC2_IP>:9000
# Default credentials: admin/admin (change immediately!)

# Add SonarQube scan to Jenkins pipeline:
stage('SonarQube Analysis') {
  steps {
    withSonarQubeEnv('sonarqube') {
      sh 'mvn sonar:sonar'  # For Java services
    }
  }
}
```

---

## 9. Compliance Checklist

| Control | Status | Implementation |
|---------|--------|----------------|
| Encryption at rest (EBS) | ✅ | `encrypted = true` |
| Encryption at rest (S3) | ✅ | AES256 SSE |
| Encryption at rest (EKS secrets) | ✅ | KMS envelope encryption |
| Encryption at rest (ECR) | ✅ | KMS encryption |
| IMDSv2 enforced | ✅ | `http_tokens = required` |
| No public S3 buckets | ✅ | `block_public_acls = true` |
| Non-root containers | ✅ | `runAsNonRoot: true` |
| Read-only container filesystems | ✅ | `readOnlyRootFilesystem: true` |
| Dropped Linux capabilities | ✅ | `capabilities.drop: [ALL]` |
| Immutable container tags | ✅ | `image_tag_mutability = IMMUTABLE` |
| Container vulnerability scanning | ✅ | `scan_on_push = true` |
| IaC security scanning | ✅ | Trivy in Jenkins pipeline |
| EKS audit logging | ✅ | All 5 log types enabled |
| State file encryption | ✅ | S3 AES256 |
| Secrets not in Git | ✅ | .gitignore rules |
| MFA on AWS root account | ⚠️ | Manual — not Terraform managed |
| VPC Flow Logs | ❌ | Not implemented (roadmap) |
| AWS Config rules | ❌ | Not implemented (roadmap) |
| WAF on LoadBalancer | ❌ | Not implemented (roadmap) |
