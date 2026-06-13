# ⚡ Quick Start Guide

> **Goal:** Deploy the complete AWS EKS DevSecOps platform from zero to running Kubernetes cluster in under 30 minutes.

---

## Prerequisites

Before starting, ensure you have:

```bash
# Check Terraform version (need >= 1.12)
terraform version

# Check AWS CLI version (need v2)
aws --version

# Check Git
git --version

# Check kubectl (optional, for post-deploy)
kubectl version --client
```

---

## Step 1: Configure AWS Authentication

```bash
# Option A: AWS CLI configure (interactive)
aws configure
# Enter: Access Key ID, Secret Access Key, Region: ap-southeast-1, Output: json

# Option B: Environment variables
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="ap-southeast-1"

# Verify authentication
aws sts get-caller-identity
# Expected output:
# {
#   "UserId": "AIDAXCJHIGQYV6OEVH4XJ",
#   "Account": "485950501937",
#   "Arn": "arn:aws:iam::485950501937:user/DevOps-IaC-User"
# }
```

---

## Step 2: Clone the Repository

```bash
git clone https://github.com/LearningGallery/AWS-EKS-DevSecOps-Project.git
cd AWS-EKS-DevSecOps-Project
```

---

## Step 3: Deploy the Bootstrap (State Backend)

> **What is this?** The bootstrap creates the S3 bucket and DynamoDB table that Terraform uses to store its state file. This must run **before** the main infrastructure.

```bash
# Navigate to bootstrap directory
cd Project/LearningGallery/Infra-Code_UAT/terraform-bootstrap

# Initialize Terraform
terraform init

# Preview what will be created
terraform plan
# Expected: 6 resources to add (S3 bucket + versioning + encryption + public access block + DynamoDB table)

# Apply
terraform apply -auto-approve

# Note the outputs — you will need the bucket name
terraform output
# Expected:
# state_bucket_names = {
#   "core_uat" = "st-cis-uat-tfstate-485950501937"
# }
# deployed_account_id = "485950501937"
```

---

## Step 4: Configure Remote Backend

```bash
# Navigate to main infrastructure directory
cd ../

# Verify backend.tf has the correct bucket name
cat backend.tf
# Should show:
# bucket = "st-cis-uat-tfstate-<YOUR_ACCOUNT_ID>"
# If your account ID differs, update it:
sed -i 's/485950501937/YOUR_ACCOUNT_ID/g' backend.tf
```

---

## Step 5: Initialize Main Infrastructure

```bash
# Initialize with remote backend
terraform init

# Expected output:
# Initializing the backend...
# Successfully configured the backend "s3"!
# Initializing modules...
# - core_iam in ../../../modules/iam
# - core_vpc in ../../../modules/vpc
# - ec2_infrastructure in ../../../modules/ec2
# - core_ecr in ../../../modules/ecr
# - core_eks in ../../../modules/eks
# Terraform has been successfully initialized!
```

---

## Step 6: Validate Configuration

```bash
# Check for syntax errors
terraform validate
# Expected: Success! The configuration is valid.

# Format check
terraform fmt -check -recursive
```

---

## Step 7: Preview Deployment

```bash
# Generate execution plan
terraform plan -out=tfplan

# Review the plan — look for:
# - Number of resources to add (expected ~45-55)
# - No unexpected destroy operations
# - Module dependencies resolved correctly

# Key resources you should see:
# + module.core_iam.aws_iam_role.role["ec2-profile"]
# + module.core_iam.aws_iam_role.role["eks-master"]
# + module.core_iam.aws_iam_role.role["eks-node"]
# + module.core_vpc["core"].aws_vpc.vpc
# + module.core_vpc["core"].aws_subnet.subnets["web_az1"]
# + module.core_vpc["core"].aws_subnet.subnets["web_az2"]
# + module.core_vpc["core"].aws_subnet.subnets["eks_az1"]
# + module.core_vpc["core"].aws_subnet.subnets["eks_az2"]
# + module.ec2_infrastructure["mgm"].aws_instance.instances[0]
# + module.core_ecr.aws_ecr_repository.registry["frontend"]
# + module.core_eks["eks_main"].aws_eks_cluster.main
# + module.core_eks["eks_main"].aws_eks_node_group.nodes["ng_app"]
```

---

## Step 8: Deploy Infrastructure

```bash
# Apply the saved plan
terraform apply tfplan

# OR apply with auto-approve (skip confirmation)
terraform apply -auto-approve

# Deployment timeline:
# ~2 min  — IAM roles, VPC, subnets, security groups, ECR repos
# ~12 min — EKS cluster creation (longest step)
# ~5 min  — EKS node groups
# ~1 min  — OIDC provider, access entries
# Total:  ~20-25 minutes
```

---

## Step 9: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name cis-uat-eks_main

# Verify cluster access
kubectl get nodes
# Expected output:
# NAME                                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-xxx.ap-southeast-1.compute.internal Ready    <none>   5m    v1.31.x
# ip-10-0-2-xxx.ap-southeast-1.compute.internal Ready    <none>   5m    v1.31.x
# ip-10-0-1-yyy.ap-southeast-1.compute.internal Ready    <none>   4m    v1.31.x
```

---

## Step 10: Deploy Microservices

```bash
# Apply all Kubernetes manifests
kubectl apply -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/

# Watch pods start up
kubectl get pods --watch

# Check all pods are Running
kubectl get pods
# Expected: All 12 deployments Running (11 services + redis-cart)

# Get the frontend LoadBalancer URL
kubectl get service frontend-external
# Note the EXTERNAL-IP — this is your application URL
# Access: http://<EXTERNAL-IP>
```

---

## Step 11: Access Jenkins

```bash
# Get the management EC2 public IP
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text

# Access Jenkins
# URL: http://<EC2_PUBLIC_IP>:8080

# Get initial Jenkins admin password (SSH to EC2 first)
ssh -i learninggallery.pem ec2-user@<EC2_PUBLIC_IP>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Next Steps

After successful deployment:

1. **Set up Jenkins pipelines** — Use `Apps-Code_UAT/jenkinsfiles/master-orchestrator` to build all 11 services
2. **Configure SonarQube** — Access at `http://<EC2_IP>:9000` (default: admin/admin)
3. **Install ArgoCD** — For GitOps-based continuous deployment
4. **Install Prometheus/Grafana** — For cluster monitoring (Helm charts in bootstrap script)
5. **Review security groups** — Restrict `0.0.0.0/0` rules to specific IPs for production

> 📖 Detailed deployment guide: [docs/08-DEPLOYMENT-GUIDE.md](docs/08-DEPLOYMENT-GUIDE.md)
