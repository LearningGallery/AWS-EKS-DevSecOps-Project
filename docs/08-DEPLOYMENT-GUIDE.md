# 🚀 Deployment Guide

---

## 1. Pre-Deployment Checklist

```
Infrastructure:
  [ ] AWS account with sufficient service limits
  [ ] IAM user/role with required permissions
  [ ] EC2 key pair created (name: learninggallery or custom)
  [ ] Default EKS service-linked role exists

Local Environment:
  [ ] Terraform >= 1.12.0 installed
  [ ] AWS CLI v2 installed and configured
  [ ] Git installed
  [ ] Sufficient disk space (~500MB for providers)

Configuration:
  [ ] backend.tf updated with correct account ID
  [ ] data/vpcs.csv reviewed
  [ ] data/infrastructure.csv AMI ID is valid for ap-southeast-1
  [ ] data/eks_clusters.csv K8s version supported
  [ ] SSH key pair name matches data/infrastructure.csv key_name field
```

---

## 2. Authentication Setup

### Option A: IAM User (Development)

```bash
# Create access keys for IAM user
aws iam create-access-key --user-name DevOps-IaC-User

# Configure locally
aws configure
AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name: ap-southeast-1
Default output format: json
```

### Option B: IAM Role with MFA (Recommended for production)

```bash
# Assume role with MFA
aws sts assume-role \
  --role-arn "arn:aws:iam::485950501937:role/TerraformDeployRole" \
  --role-session-name "TerraformDeploy" \
  --serial-number "arn:aws:iam::485950501937:mfa/DevOps-IaC-User" \
  --token-code "123456"

# Export the temporary credentials
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

### Option C: EC2 Instance Profile (CI/CD)

```bash
# If running Terraform from an EC2 instance with an instance profile,
# no credential configuration is needed — AWS SDK auto-discovers them
aws sts get-caller-identity  # Verify it works
```

---

## 3. Deployment Phases

### Phase 1: Bootstrap (One-Time)

```bash
cd Project/LearningGallery/Infra-Code_UAT/terraform-bootstrap

# Initialize
terraform init

# Deploy S3 + DynamoDB for state management
terraform apply -auto-approve

# Record outputs
terraform output -json > bootstrap_outputs.json
cat bootstrap_outputs.json
```

**Resources created:**
- `st-cis-uat-tfstate-485950501937` — S3 state bucket
- `tb-cis-uat-tflocks` — DynamoDB lock table

---

### Phase 2: Core Infrastructure

```bash
cd Project/LearningGallery/Infra-Code_UAT

# Initialize with remote backend
terraform init \
  -backend-config="bucket=st-cis-uat-tfstate-485950501937" \
  -backend-config="key=core-infra/terraform.tfstate" \
  -backend-config="region=ap-southeast-1"

# Validate
terraform validate

# Plan with detailed output
terraform plan \
  -out=tfplan \
  -var="aws_region=ap-southeast-1"

# Review plan output carefully
# Key things to verify:
#   - All 4 subnets created
#   - 3 IAM roles created
#   - 11 ECR repos created
#   - 1 EKS cluster created
#   - 1 EC2 instance created

# Apply
terraform apply tfplan
```

**Deployment order (Terraform resolves automatically):**

```
1. IAM Roles (ec2-profile, eks-master, eks-node)
2. IAM Policies (custom attachments)
3. IAM Instance Profiles
4. VPC + Internet Gateway
5. Subnets (4x)
6. Route Tables + Associations
7. Security Groups + Rules
8. Network ACLs + Rules
9. ECR Repositories (11x)
10. ECR Lifecycle Policies (11x)
11. EC2 Instance (mgm)
12. KMS Key (for EKS)
13. EKS Cluster
14. EKS Node Group
15. TLS Certificate Data Source (reads OIDC)
16. OIDC Provider
17. EKS Access Entry + Policy Association
```

---

### Phase 3: Application Deployment

```bash
# Configure kubectl
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name cis-uat-eks_main

# Verify cluster access
kubectl cluster-info
kubectl get nodes

# Deploy all microservices
cd Project/LearningGallery/Apps-Code_UAT/kubernetes-files

# Apply manifests in order
kubectl apply -f redis-cart.yaml
kubectl apply -f adservice.yaml
kubectl apply -f currencyservice.yaml
kubectl apply -f emailservice.yaml
kubectl apply -f paymentservice.yaml
kubectl apply -f productcatalogservice.yaml
kubectl apply -f cartservice.yaml
kubectl apply -f recommendationservice.yaml
kubectl apply -f shippingservice.yaml
kubectl apply -f checkoutservice.yaml
kubectl apply -f frontend.yaml
kubectl apply -f loadgenerator.yaml

# Or apply all at once
kubectl apply -f .

# Watch pods come up
kubectl get pods -w
```

---

## 4. Post-Deployment Validation

### Validate Infrastructure

```bash
# VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=vp-cis-uat-ia-01" \
  --query "Vpcs[0].{ID:VpcId,CIDR:CidrBlock,State:State}"

# Subnets
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<VPC_ID>" \
  --query "Subnets[*].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch}"

# EKS Cluster
aws eks describe-cluster \
  --name cis-uat-eks_main \
  --region ap-southeast-1 \
  --query "cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}"

# ECR Repositories
aws ecr describe-repositories \
  --region ap-southeast-1 \
  --query "repositories[*].{Name:repositoryName,URI:repositoryUri}"

# EC2 Instance
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --query "Reservations[0].Instances[0].{ID:InstanceId,State:State.Name,IP:PublicIpAddress,Type:InstanceType}"
```

### Validate Kubernetes

```bash
# Check nodes
kubectl get nodes -o wide
# Expected: 3 nodes in Ready state

# Check all system pods
kubectl get pods -n kube-system
# Expected: All Running

# Check application pods
kubectl get pods
# Expected: All 12 deployments Running

# Check services
kubectl get svc
# Expected: frontend-external shows EXTERNAL-IP (LoadBalancer)

# Test frontend
FRONTEND_IP=$(kubectl get svc frontend-external -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -s -o /dev/null -w "%{http_code}" http://$FRONTEND_IP
# Expected: 200
```

### Validate CI/CD

```bash
# Get Jenkins URL
EC2_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "Jenkins URL: http://$EC2_IP:8080"
echo "SonarQube URL: http://$EC2_IP:9000"

# Verify Jenkins is running
curl -s -o /dev/null -w "%{http_code}" http://$EC2_IP:8080
# Expected: 200 or 403 (login required)
```

---

## 5. Rollback Procedures

### Rollback a Specific Module

```bash
# Example: Rollback only EKS node group changes
terraform plan -target=module.core_eks -out=rollback.tfplan
terraform apply rollback.tfplan
```

### Rollback Using State

```bash
# List state resources
terraform state list

# Remove a resource from state (does NOT destroy it)
terraform state rm module.core_eks["eks_main"].aws_eks_node_group.nodes["ng_app"]

# Re-import if needed
terraform import module.core_eks["eks_main"].aws_eks_node_group.nodes["ng_app"] \
  "cis-uat-eks_main:cis-uat-ng_app"
```

### Full Infrastructure Teardown

```bash
# Step 1: Remove Kubernetes resources first (avoids LoadBalancer orphans)
kubectl delete -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/

# Step 2: Wait for LoadBalancer to be deprovisioned
kubectl get svc frontend-external -w
# Wait until EXTERNAL-IP is removed

# Step 3: Destroy Terraform infrastructure
cd Project/LearningGallery/Infra-Code_UAT
terraform destroy -auto-approve

# Step 4: Destroy bootstrap (optional - preserves state history)
cd terraform-bootstrap
terraform destroy -auto-approve
```

---

## 6. Multi-Environment Deployment Pattern

To deploy to a different environment (e.g., `prod`), duplicate the data directory:

```bash
# Create prod configuration
mkdir -p Project/LearningGallery/Infra-Code_PROD
cp -r Project/LearningGallery/Infra-Code_UAT/* \
      Project/LearningGallery/Infra-Code_PROD/

# Update CSV files for prod
sed -i 's/uat/prd/g' Project/LearningGallery/Infra-Code_PROD/data/*.csv
sed -i 's/10.0./10.1./g' Project/LearningGallery/Infra-Code_PROD/data/subnets.csv
sed -i 's/10.0./10.1./g' Project/LearningGallery/Infra-Code_PROD/data/vpcs.csv

# Update backend key
cat > Project/LearningGallery/Infra-Code_PROD/backend.tf << EOF
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "prod-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
EOF

# Deploy prod
cd Project/LearningGallery/Infra-Code_PROD
terraform init && terraform apply
```