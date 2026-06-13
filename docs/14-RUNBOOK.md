# 📋 Runbook

This runbook provides the **day-2 operational procedures** for managing the AWS EKS DevSecOps Platform.  
Use it as the practical operations guide for deploying changes, scaling services, responding to incidents, backing up state, and safely destroying infrastructure.

---

## Table of Contents

- [1. Daily Operations](#1-daily-operations)
- [2. Deploy New Infrastructure](#2-deploy-new-infrastructure)
- [3. Update Infrastructure](#3-update-infrastructure)
- [4. Deploy New Microservice](#4-deploy-new-microservice)
- [5. Handle Incidents](#5-handle-incidents)
- [6. Respond to ECR Security Findings](#6-respond-to-ecr-security-findings)
- [7. Backup Procedures](#7-backup-procedures)
- [8. Destroy Infrastructure](#8-destroy-infrastructure)
- [9. Emergency Procedures](#9-emergency-procedures)

---

## 1. Daily Operations

### Purpose

These checks help confirm that the platform is healthy and operating normally.

### Check Cluster Health

```bash
# Node status
kubectl get nodes
# Expected: All nodes Ready

# Pod status across all namespaces
kubectl get pods -A
# Expected: All pods Running or Completed

# Recent events (look for warnings/errors)
kubectl get events --sort-by='.lastTimestamp' -A | tail -20
```

### Check Application Services

```bash
# List all services
kubectl get svc

# Check frontend external endpoint
kubectl get svc frontend-external

# Check deployments
kubectl get deployments
```

### Check ECR Image Counts

```bash
# List image counts per repository
for repo in adservice cartservice checkoutservice currencyservice emailservice \
            frontend loadgenerator paymentservice productcatalogservice \
            recommendationservice shippingservice; do
  count=$(aws ecr describe-images \
    --repository-name "cis-uat-${repo}" \
    --region ap-southeast-1 \
    --query "length(imageDetails)" \
    --output text)
  echo "${repo}: ${count} images"
done
```

### Check EC2 Management Server Health

```bash
# Get EC2 instance status
aws ec2 describe-instance-status \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --region ap-southeast-1 \
  --query "InstanceStatuses[*].{Instance:InstanceId,State:InstanceState.Name,System:SystemStatus.Status,InstanceStatus:InstanceStatus.Status}"
```

### Check Jenkins Availability

```bash
# Replace with actual EC2 public IP if needed
curl -I http://<EC2_PUBLIC_IP>:8080
# Expected: HTTP 200 or 403 depending on auth config
```

---

## 2. Deploy New Infrastructure

### Purpose

Use this procedure when adding or modifying infrastructure resources such as:
- VPC subnets
- security group rules
- EKS node groups
- EC2 instances
- ECR repositories
- IAM roles

### Procedure

```bash
# Step 1: Navigate to the root Terraform directory
cd Project/LearningGallery/Infra-Code_UAT

# Step 2: Edit the relevant CSV file
vim data/subnets.csv
# or infrastructure.csv, eks_node_groups.csv, sg_rules.csv, etc.

# Step 3: Validate Terraform syntax
terraform validate

# Step 4: Format Terraform code
terraform fmt -recursive

# Step 5: Preview changes
terraform plan -out=tfplan

# Step 6: Review plan carefully
# Look for:
# - additions (green)
# - changes (yellow)
# - destructions (red)

# Step 7: Apply approved plan
terraform apply tfplan

# Step 8: Verify resource now exists in state
terraform state list | grep <new_resource>
```

### Post-Deployment Validation

```bash
# Example: verify subnets
aws ec2 describe-subnets --region ap-southeast-1

# Example: verify EKS node groups
aws eks list-nodegroups \
  --cluster-name cis-uat-eks_main \
  --region ap-southeast-1

# Example: verify ECR repos
aws ecr describe-repositories --region ap-southeast-1
```

---

## 3. Update Infrastructure

### Purpose

Use this section for controlled updates to existing infrastructure.

---

### Upgrade Kubernetes Version

```bash
# Step 1: Check available Kubernetes versions
aws eks describe-addon-versions \
  --region ap-southeast-1 \
  --query "addons[0].addonVersions[0].compatibilities[*].clusterVersion" \
  --output text | tr '\t' '\n' | sort -V

# Step 2: Update eks_clusters.csv
# Change: k8s_version from 1.31 to target version, e.g. 1.32

# Step 3: Plan EKS changes
terraform plan -target=module.core_eks

# Step 4: Apply EKS changes
terraform apply -target=module.core_eks

# Step 5: Monitor node group status
aws eks describe-nodegroup \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --region ap-southeast-1 \
  --query "nodegroup.{Status:status,Version:version}"
```

### Scale Node Group

#### Method 1: Recommended — Update CSV and Apply Terraform

```bash
# Edit data/eks_node_groups.csv
# Example:
# ng_app,eks_main,t3.large,ON_DEMAND,2,10,5,20
# desired_size = 5

terraform plan -target=module.core_eks
terraform apply -target=module.core_eks
```

#### Method 2: Temporary — Direct AWS CLI

> Warning: this creates drift from Terraform until the next apply.

```bash
aws eks update-nodegroup-config \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --scaling-config desiredSize=5 \
  --region ap-southeast-1
```

### Update EC2 Management Instance Bootstrap Logic

If you update the user data script:

```bash
# Edit the script
vim scripts/updated_install-tools.sh

# Re-run plan
terraform plan -target=module.ec2_infrastructure

# Apply changes
terraform apply -target=module.ec2_infrastructure
```

> Note: Because `user_data_replace_on_change = true`, Terraform may replace the EC2 instance.

---

## 4. Deploy New Microservice

### Purpose

Use this procedure when introducing a brand-new application service into the platform.

### Step 1: Add ECR Repository

```bash
cd Project/LearningGallery/Infra-Code_UAT

echo "cis,uat,newservice,IMMUTABLE,TRUE,30" >> data/ecr_repositories.csv

terraform plan -target=module.core_ecr
terraform apply -target=module.core_ecr
```

### Step 2: Create Kubernetes Manifest

```bash
cat > Project/LearningGallery/Apps-Code_UAT/kubernetes-files/newservice.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: newservice
spec:
  selector:
    matchLabels:
      app: newservice
  template:
    metadata:
      labels:
        app: newservice
    spec:
      serviceAccountName: default
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
      containers:
      - name: server
        image: 485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-newservice:latest
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          privileged: false
          capabilities:
            drop:
              - ALL
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: newservice
spec:
  type: ClusterIP
  selector:
    app: newservice
  ports:
  - port: 8080
    targetPort: 8080
EOF
```

### Step 3: Create Jenkins Pipeline File

```bash
cp Project/LearningGallery/Apps-Code_UAT/jenkinsfiles/frontend \
   Project/LearningGallery/Apps-Code_UAT/jenkinsfiles/newservice
```

Then update:
- `IMAGE_NAME`
- `REPO_URL`
- `YAML_FILE`
- source build path

### Step 4: Add to Master Orchestrator

Edit:

```bash
vim Project/LearningGallery/Apps-Code_UAT/jenkinsfiles/master-orchestrator
```

Add a new stage:

```groovy
stage('Build New Service') { steps { script { buildAndPush('newservice') } } }
```

Also add the service to the YAML update loop:

```groovy
for SERVICE in adservice cartservice checkoutservice currencyservice emailservice frontend loadgenerator paymentservice productcatalogservice recommendationservice shippingservice newservice; do
```

### Step 5: Deploy the Service

```bash
kubectl apply -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/newservice.yaml

kubectl get pods
kubectl get svc newservice
```

---

## 5. Handle Incidents

### Purpose

Use these procedures when workloads or infrastructure behave unexpectedly.

---

### Pod CrashLoopBackOff

```bash
# Identify failing pods
kubectl get pods

# View pod logs
kubectl logs <pod-name>

# View previous crash logs
kubectl logs <pod-name> --previous

# Describe pod for events
kubectl describe pod <pod-name>
```

#### Common Causes
- invalid environment variable
- bad image tag
- insufficient memory
- failing liveness probe
- downstream dependency unavailable

#### Recovery
```bash
# Restart deployment
kubectl rollout restart deployment/<deployment-name>

# Check rollout
kubectl rollout status deployment/<deployment-name>
```

---

### ImagePullBackOff

```bash
kubectl describe pod <pod-name>
```

Check:
- image exists in ECR
- node IAM role includes `AmazonEC2ContainerRegistryReadOnly`
- image tag is correct
- ECR repo name matches YAML

Verify image exists:

```bash
aws ecr list-images \
  --repository-name cis-uat-frontend \
  --region ap-southeast-1
```

---

### Pending Pods

```bash
kubectl get pods | grep Pending
kubectl describe pod <pod-name>
```

Common causes:
- insufficient CPU
- insufficient memory
- no matching nodes
- taints/tolerations mismatch

Scale node group if needed:

```bash
aws eks update-nodegroup-config \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --scaling-config desiredSize=5 \
  --region ap-southeast-1
```

---

### Node NotReady

```bash
kubectl get nodes
kubectl describe node <node-name>
```

If node is unhealthy:

```bash
# Stop scheduling to the node
kubectl cordon <node-name>

# Drain workloads
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

Then terminate the backing EC2 instance if necessary:

```bash
aws ec2 terminate-instances --instance-ids <instance-id> --region ap-southeast-1
```

EKS managed node group should replace it automatically.

---

## 6. Respond to ECR Security Findings

### Purpose

Use this procedure when ECR scan-on-push identifies critical vulnerabilities.

### Step 1: Check Critical Findings

```bash
aws ecr describe-image-scan-findings \
  --repository-name cis-uat-frontend \
  --image-id imageTag=<TAG> \
  --region ap-southeast-1 \
  --query "imageScanFindings.findings[?severity=='CRITICAL'].{Name:name,Severity:severity,Package:attributes[?key=='package name'].value|[0]}"
```

### Step 2: Rebuild Patched Image

- update the base image or dependencies
- trigger the Jenkins pipeline for the affected service
- produce a new immutable tag

### Step 3: Verify New Image Findings

```bash
aws ecr describe-image-scan-findings \
  --repository-name cis-uat-frontend \
  --image-id imageTag=<NEW_TAG> \
  --region ap-southeast-1 \
  --query "imageScanFindings.findingSeverityCounts"
```

### Step 4: Update Kubernetes Deployment

```bash
kubectl set image deployment/frontend \
  server=485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-frontend:<NEW_TAG>
```

### Step 5: Verify Rollout

```bash
kubectl rollout status deployment/frontend
kubectl get pods
```

---

## 7. Backup Procedures

### Purpose

Backups protect Terraform state and Kubernetes configuration before major changes.

---

### Backup Terraform State

```bash
# Manual backup before any major change
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
terraform state pull > "terraform_state_backup_${BACKUP_DATE}.tfstate"

# Store backup in S3
aws s3 cp "terraform_state_backup_${BACKUP_DATE}.tfstate" \
  s3://st-cis-uat-tfstate-485950501937/backups/

# List backups
aws s3 ls s3://st-cis-uat-tfstate-485950501937/backups/
```

### Backup Kubernetes Resources

```bash
# Export all Kubernetes manifests
kubectl get all -A -o yaml > k8s_backup_$(date +%Y%m%d).yaml

# Export specific namespace
kubectl get all -n default -o yaml > k8s_default_backup.yaml

# Export secrets
kubectl get secrets -A -o yaml > k8s_secrets_backup.yaml
```

> Note: Kubernetes secret exports should be protected carefully, even if cluster-side encryption is enabled.

---

## 8. Destroy Infrastructure

### Purpose

Use this procedure when the environment is no longer needed.

### Step 1: Remove Kubernetes Resources First

```bash
kubectl delete -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/
```

This helps prevent:
- orphaned LoadBalancers
- orphaned ENIs
- delayed EKS deletion

### Step 2: Wait for LoadBalancer Cleanup

```bash
echo "Waiting for LoadBalancer deprovisioning..."
kubectl get svc -w
```

Wait until `frontend-external` no longer shows an external endpoint.

### Step 3: Backup State

```bash
terraform state pull > final_state_backup_$(date +%Y%m%d_%H%M%S).tfstate
```

### Step 4: Destroy Main Infrastructure

```bash
cd Project/LearningGallery/Infra-Code_UAT
terraform destroy
```

Review the plan carefully before typing `yes`.

### Step 5: Destroy Bootstrap Resources (Optional)

> Warning: Only do this if you are permanently decommissioning the environment and no longer need the Terraform state bucket.

```bash
cd terraform-bootstrap
terraform destroy
```

If `prevent_destroy = true` is present, remove or adjust it before destroy.

---

## 9. Emergency Procedures

### Purpose

Use these procedures for severe service-impacting failures.

---

### EKS Cluster Completely Down

```bash
# Step 1: Check cluster status
aws eks describe-cluster \
  --name cis-uat-eks_main \
  --region ap-southeast-1 \
  --query "cluster.status"
```

### Step 2: Check CloudWatch Log Groups

```bash
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/cis-uat-eks_main"
```

### Step 3: Refresh Terraform State

```bash
terraform refresh
```

### Step 4: Recreate EKS if Unrecoverable

```bash
terraform destroy -target=module.core_eks
terraform apply -target=module.core_eks
```

### Step 5: Reconfigure kubectl and Redeploy Apps

```bash
aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main
kubectl apply -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/
```

---

### Management EC2 Unreachable

```bash
# Step 1: Check instance health
aws ec2 describe-instance-status \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --region ap-southeast-1 \
  --query "InstanceStatuses[0].{InstanceState:InstanceState.Name,SystemStatus:SystemStatus.Status}"
```

### Step 2: Reboot Instance

```bash
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --region ap-southeast-1 \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

aws ec2 reboot-instances --instance-ids $INSTANCE_ID --region ap-southeast-1
```

### Step 3: Use SSM Session Manager if SSH Fails

```bash
aws ssm start-session --target $INSTANCE_ID
```

### Step 4: Recreate EC2 if Unrecoverable

```bash
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region ap-southeast-1
terraform apply -target=module.ec2_infrastructure
```

Because the server is Terraform-managed, recreation is usually the cleanest recovery path.

---

## Operational Notes

### Recommended Safety Practices

- Always run `terraform plan` before `terraform apply`
- Always back up state before destructive or high-impact changes
- Prefer Terraform-managed changes over direct AWS CLI changes
- Avoid manual drift unless it is part of emergency recovery
- Record incident timelines and remediation steps after recovery

### Useful Quick Commands

```bash
# Terraform
terraform validate
terraform fmt -recursive
terraform plan
terraform apply
terraform state list

# Kubernetes
kubectl get nodes
kubectl get pods -A
kubectl get svc
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# AWS
aws eks describe-cluster --name cis-uat-eks_main --region ap-southeast-1
aws ecr describe-repositories --region ap-southeast-1
aws ec2 describe-instances --region ap-southeast-1
```
