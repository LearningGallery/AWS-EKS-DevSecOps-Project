# 🏗️ Architecture

---

## 1. Logical Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Account (ap-southeast-1)                │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    VPC: cis-uat-ia (10.0.0.0/16)            │   │
│  │                                                             │   │
│  │  ┌─────────────────────────┐  ┌─────────────────────────┐  │   │
│  │  │   AZ: ap-southeast-1a   │  │   AZ: ap-southeast-1b   │  │   │
│  │  │                         │  │                         │  │   │
│  │  │  ┌───────────────────┐  │  │  ┌───────────────────┐  │  │   │
│  │  │  │  web_az1 (Public) │  │  │  │  web_az2 (Public) │  │  │   │
│  │  │  │  10.0.1.0/24      │  │  │  │  10.0.2.0/24      │  │  │   │
│  │  │  │  [EC2 Jenkins VM] │  │  │  │                   │  │  │   │
│  │  │  └───────────────────┘  │  │  └───────────────────┘  │  │   │
│  │  │                         │  │                         │  │   │
│  │  │  ┌───────────────────┐  │  │  ┌───────────────────┐  │  │   │
│  │  │  │  eks_az1(Private) │  │  │  │  eks_az2(Private) │  │  │   │
│  │  │  │  10.0.10.0/24     │  │  │  │  10.0.11.0/24     │  │  │   │
│  │  │  │  [EKS Nodes]      │  │  │  │  [EKS Nodes]      │  │  │   │
│  │  │  └───────────────────┘  │  │  └───────────────────┘  │  │   │
│  │  └─────────────────────────┘  └─────────────────────────┘  │   │
│  │                                                             │   │
│  │          ┌──────────────────────────────┐                  │   │
│  │          │   EKS Control Plane          │                  │   │
│  │          │   cis-uat-eks_main (K8s 1.31)│                  │   │
│  │          │   KMS Encrypted Secrets      │                  │   │
│  │          │   OIDC Provider (IRSA)        │                  │   │
│  │          └──────────────────────────────┘                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌──────────────────┐  ┌───────────────────┐  ┌────────────────┐  │
│  │  ECR (11 Repos)  │  │  IAM              │  │  S3 State      │  │
│  │  KMS Encrypted   │  │  3 Roles          │  │  + Lock File   │  │
│  │  Immutable Tags  │  │  OIDC Provider    │  │                │  │
│  └──────────────────┘  └───────────────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Network Topology

### Subnet Layout

| Subnet ID | CIDR | AZ | Type | Role | Resources |
|-----------|------|----|------|------|-----------|
| `web_az1` | `10.0.1.0/24` | `ap-southeast-1a` | Public | web | Jenkins EC2 |
| `web_az2` | `10.0.2.0/24` | `ap-southeast-1b` | Public | web | (reserved) |
| `eks_az1` | `10.0.10.0/24` | `ap-southeast-1a` | Private | eks | EKS nodes |
| `eks_az2` | `10.0.11.0/24` | `ap-southeast-1b` | Private | eks | EKS nodes |

### Security Group Rules (from sg_rules.csv)

| SG | Direction | Port | Protocol | Source | Purpose |
|----|-----------|------|----------|--------|---------|
| `web` | ingress | 443 | TCP | 0.0.0.0/0 | HTTPS |
| `web` | ingress | 22 | TCP | 0.0.0.0/0 | SSH |
| `web` | ingress | 8080 | TCP | 0.0.0.0/0 | Jenkins |
| `web` | ingress | 9000 | TCP | 0.0.0.0/0 | SonarQube |
| `web` | ingress | 9090 | TCP | 0.0.0.0/0 | Prometheus |
| `web` | ingress | 80 | TCP | 0.0.0.0/0 | HTTP |
| `web` | egress | 443 | TCP | 0.0.0.0/0 | HTTPS out |
| `web` | egress | 80 | TCP | 0.0.0.0/0 | HTTP out |
| `eks_default` | ingress | 0-65535 | TCP | sg-web | Node communication |

> ⚠️ **Security Note:** Several rules allow `0.0.0.0/0` — this is acceptable for a UAT/learning environment. Production should restrict source CIDRs.

### Route Tables

| Route Table | Subnets | Routes |
|-------------|---------|--------|
| `rt-cis-uat-ia-pub-01` | web_az1, web_az2 | `0.0.0.0/0 → IGW` |
| `rt-cis-uat-ia-web-01` | (private web) | Local only |
| `rt-cis-uat-ia-eks-01` | eks_az1, eks_az2 | Local only |

---

## 3. IAM Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      IAM Architecture                    │
│                                                          │
│  rl-cis-uat-ec2-profile                                  │
│  ├── Trusted: ec2.amazonaws.com                          │
│  ├── AdministratorAccess                                 │
│  ├── AmazonEC2FullAccess                                 │
│  ├── AmazonEKSClusterPolicy                              │
│  ├── AmazonEKSWorkerNodePolicy                           │
│  ├── AWSCloudFormationFullAccess                         │
│  ├── IAMFullAccess                                       │
│  └── Custom: eks_custom_policy.json (eks:*)              │
│                                                          │
│  rl-cis-uat-eks-master                                   │
│  ├── Trusted: eks.amazonaws.com                          │
│  ├── AmazonEKSClusterPolicy                              │
│  └── AmazonEKSVPCResourceController                      │
│                                                          │
│  rl-cis-uat-eks-node                                     │
│  ├── Trusted: ec2.amazonaws.com                          │
│  ├── AmazonEKSWorkerNodePolicy                           │
│  ├── AmazonEKS_CNI_Policy                                │
│  ├── AmazonEC2ContainerRegistryReadOnly                  │
│  ├── AmazonSSMManagedInstanceCore                        │
│  └── Custom: eks_autoscaler_policy.json                  │
│                                                          │
│  OIDC Provider (Zero Trust IRSA)                         │
│  └── eks.amazonaws.com OIDC → pod-level IAM              │
└──────────────────────────────────────────────────────────┘
```

---

## 4. EKS Architecture

```
┌────────────────────────────────────────────────────┐
│              EKS Cluster: cis-uat-eks_main          │
│                                                    │
│  Kubernetes Version: 1.31                          │
│  Authentication: API_AND_CONFIG_MAP                │
│  Endpoint: Public + Private                        │
│                                                    │
│  Encryption:                                       │
│  └── KMS Key → Kubernetes Secrets                  │
│                                                    │
│  Control Plane Logs:                               │
│  └── api, audit, authenticator,                    │
│      controllerManager, scheduler                  │
│                                                    │
│  Node Group: ng_app                                │
│  ├── Instance Type: t3.large                       │
│  ├── Capacity: ON_DEMAND                           │
│  └── ec2-profile → AmazonEKSClusterAdminPolicy     │
│  ├── Disk: 20                                      |
│                                                    │
│  Running Workloads (11 Microservices):             │
│  ├── frontend (LoadBalancer → port 80)             │
│  ├── adservice (ClusterIP → port 9555)             │
│  ├── cartservice (ClusterIP → port 7070)           │
│  ├── checkoutservice (ClusterIP → port 5050)       │
│  ├── currencyservice (ClusterIP → port 7000)       │
│  ├── emailservice (ClusterIP → port 5000)          │
│  ├── paymentservice (ClusterIP → port 50051)       │
│  ├── productcatalogservice (ClusterIP → port 3550) │
│  ├── recommendationservice (ClusterIP → port 8080) │
│  ├── shippingservice (ClusterIP → port 50051)      │
│  ├── loadgenerator (no service)                    │
│  └── redis-cart (ClusterIP → port 6379)            │
└────────────────────────────────────────────────────┘
```

---

## 5. CI/CD Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                          │
│                                                                 │
│  Developer                                                      │
│      │                                                          │
│      ▼ git push                                                 │
│  GitHub (main branch)                                           │
│      │                                                          │
│      ▼ trigger                                                  │
│  Jenkins (EC2 port 8080)                                        │
│      │                                                          │
│      ├── Stage 1: Checkout from Git                             │
│      │   └── Capture GIT_SHA → IMAGE_TAG = BUILD_NUM-GIT_SHA   │
│      │                                                          │
│      ├── Stage 2-12: Build Each Service (Sequential)            │
│      │   ├── docker build -t <service>:<tag> .                  │
│      │   ├── aws ecr get-login-password | docker login          │
│      │   ├── docker tag <service>:<tag> ECR_URL:<tag>           │
│      │   └── docker push ECR_URL:<tag>                          │
│      │                                                          │
│      ├── Stage 13: Update All YAMLs                             │
│      │   ├── sed -i "s#image:.*#image: ECR_URL:<tag>#g" *.yaml  │
│      │   ├── git add .                                          │
│      │   ├── git commit -m "Deploy all services: <tag>"         │
│      │   └── git push → GitHub                                  │
│      │                                                          │
│      └── Post: cleanWs() — workspace cleanup                    │
│                                                                 │
│  GitHub (updated YAMLs)                                         │
│      │                                                          │
│      ▼ kubectl apply (manual or ArgoCD)                         │
│  EKS Cluster                                                    │
│      └── 11 Microservices Running                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Disaster Recovery Approach

| Scenario | Recovery Method | RTO | RPO |
|----------|----------------|-----|-----|
| EC2 management instance failure | Re-apply Terraform, re-run bootstrap script | ~20 min | 0 (no state on instance) |
| EKS node failure | Auto-scaling group replaces node | ~5 min | 0 (stateless pods) |
| EKS cluster deletion | Re-apply Terraform | ~15 min | 0 (manifests in Git) |
| Terraform state corruption | Restore from S3 versioning | ~10 min | Last apply |
| Container image deletion | Rebuild via Jenkins pipeline | ~15 min | 0 (code in Git) |

---

## 7. Scalability Design

- **EKS Node Group**: Min 2 → Max 10 nodes via Cluster Autoscaler (autoscaler policy pre-attached)
- **Multi-AZ**: Subnets and nodes spread across `ap-southeast-1a` and `ap-southeast-1b`
- **ECR Lifecycle**: Auto-cleanup keeps only last 30 images per repo
- **CSV Engine**: Add new infrastructure rows without code changes
