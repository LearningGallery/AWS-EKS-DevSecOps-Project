# 🧩 Modules Overview

---

## 1. Module Architecture Strategy

This project uses a **flat module hierarchy** with a single root module that orchestrates all child modules. This pattern prioritises:

- **Simplicity** — One `terraform apply` deploys everything
- **Visibility** — All dependencies are explicit in `main.tf`
- **Reusability** — Each module can be used independently in other projects

```
Root Module (Infra-Code_UAT/main.tf)
├── module.core_iam          ← No dependencies (runs first)
├── module.core_vpc          ← No dependencies (runs first)
├── module.ec2_infrastructure ← Depends on: core_iam, core_vpc
├── module.core_ecr          ← No dependencies
├── module.core_eks          ← Depends on: core_iam, core_vpc
├── data.tls_certificate     ← Depends on: core_eks (reads OIDC URL)
├── aws_iam_openid_connect   ← Depends on: core_eks, tls_certificate
└── aws_eks_access_entry     ← Depends on: core_eks, core_iam
```

---

## 2. Module Dependency Graph

```
                    ┌─────────────┐
                    │  core_iam   │
                    │  (IAM)      │
                    └──────┬──────┘
                           │ role_arns
                           │ instance_profile_names
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
    ┌──────────────┐  ┌─────────┐  ┌─────────┐
    │  ec2_infra   │  │core_eks │  │core_vpc │
    │  (EC2)       │  │ (EKS)   │  │ (VPC)   │
    └──────┬───────┘  └────┬────┘  └────┬────┘
           │               │            │
           │ subnet_ids    │ oidc_url   │ subnet_ids
           │ sg_ids        │            │ sg_ids
           └──────────┬────┘            │
                      │                 │
                      ▼                 │
            ┌─────────────────┐         │
            │  OIDC Provider  │◄────────┘
            │  EKS Access     │
            │  Entry          │
            └─────────────────┘

    ┌─────────────┐    ┌─────────────┐
    │  core_ecr   │    │  core_s3    │
    │  (ECR)      │    │  (S3)       │
    └─────────────┘    └─────────────┘
    (independent)      (independent)
```

---

## 3. Module Summary

| Module | Path | for_each? | Key Pattern |
|--------|------|-----------|-------------|
| `vpc` | `modules/vpc` | ✅ Yes (per VPC) | Dynamic resources from CSV maps |
| `iam` | `modules/iam` | ❌ No (single call) | `for_each` internally over roles map |
| `ec2` | `modules/ec2` | ✅ Yes (per tier) | `count` internally for multi-instance |
| `ecr` | `modules/ecr` | ❌ No (single call) | `for_each` internally over repos map |
| `eks` | `modules/eks` | ✅ Yes (per cluster) | `for_each` internally for node groups |
| `s3` | `modules/s3` | ❌ No (single call) | `for_each` internally over buckets map |

---

## 4. Module Naming Conventions

All resources follow the naming pattern:

```
<type_prefix>-<project>-<environment>-<network_zone>-<role>-<sequence>
```

| Prefix | Resource Type | Example |
|--------|--------------|---------|
| `vp-` | VPC | `vp-cis-uat-ia-01` |
| `sn-` | Subnet | `sn-cis-uat-ia-web-1a-01` |
| `sg-` | Security Group | `sg-cis-uat-ia-web-01` |
| `nl-` | Network ACL | `nl-cis-uat-ia-web-01` |
| `rt-` | Route Table | `rt-cis-uat-ia-pub-01` |
| `ig-` | Internet Gateway | `ig-cis-uat-ia-01` |
| `vm-` | EC2 Instance | `vm-cis-uat-ie-tvm-01` |
| `vol-` | EBS Volume | `vol-cis-uat-ie-tvm-01` |
| `rl-` | IAM Role | `rl-cis-uat-eks-master` |
| `pl-` | IAM Policy | `pl-cis-uat-ec2-profile-custom` |
| `ip-` | Instance Profile | `ip-cis-uat-ec2-profile` |
| `st-` | S3 Bucket | `st-cis-uat-tfstate-485950501937` |
| `tb-` | DynamoDB Table | `tb-cis-uat-tflocks` |

---

## 5. Module Reusability

Each module is designed to be reused independently. Example of using just the VPC module:

```hcl
module "my_vpc" {
  source       = "../../modules/vpc"
  project_code = "myproject"
  environment  = "prod"
  network_zone = "ia"
  vpc_cidr     = "172.16.0.0/16"

  subnets = {
    pub_az1 = {
      cidr_block = "172.16.1.0/24"
      az         = "ap-southeast-1a"
      is_public  = true
      role       = "web"
    }
  }

  sg_rules   = []
  nacl_rules = []
  route_rules = [{
    route_table_role = "pub"
    destination_cidr = "0.0.0.0/0"
    target_type      = "igw"
  }]
}
```
