# 📋 Runbook

---

## 1. Daily Operations

### Check Cluster Health

```bash
# Node status
kubectl get nodes
# Expected: All nodes Ready

# Pod status
kubectl get pods -A
# Expected: All pods Running or Completed

# Recent events (look for warnings)
kubectl get events --sort-by='.lastTimestamp' -A | tail -20
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

---

## 2. Deploy New Infrastructure

```bash
# Step 1: Edit the relevant CSV file
vim data/subnets.csv  # or infrastructure.csv, eks_node_groups.csv, etc.

# Step 2: Validate
terraform validate
terraform fmt -recursive

# Step 3: Preview changes
terraform plan -out=tfplan

# Step 4: Review plan carefully
# Look for: additions (green), changes (yellow), destructions (red)

# Step 5: Apply
terraform apply tfplan

# Step 6: Verify
terraform state list | grep <new_resource>
```

---

## 3. Update Infrastructure

### Upgrade Kubernetes Version

```bash
# Step 1: Check available versions
aws eks describe-addon-versions \
  --region ap-southeast-1 \
  --query "addons[0].addonVersions[0].compatibilities[*].clusterVersion" \
  --output text | tr '\t' '\n' | sort -V

# Step 2: Update eks_clusters.csv
# Change: k8s_version from 1.31 to 1.32

# Step 3: Plan and apply
terraform plan -target=module.core_eks
terraform apply -target=module.core_eks

# Step 4: Update node group AMI
# EKS managed node groups auto-update to compatible AMI
# Monitor: 
aws eks describe-nodegroup \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --query "nodegroup.{Status:status,Version:version}"
```

### Scale Node Group

```bash
# Method 1: Update CSV and apply Terraform
# Edit data/eks_node_groups.csv:
# ng_app,eks_main,t3.large,ON_DEMAND,2,10,5,20  ← desired_size = 5

terraform plan -target=module.core_eks
terraform apply -target=module.core_eks

# Method 2: Direct AWS CLI (not reflected in Terraform — use carefully)
aws eks update-nodegroup-config \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --scaling-config desiredSize=5 \
  --region ap-southeast-1
```

---

## 4. Deploy New Microservice

```bash
# Step 1: Add ECR repository
echo "cis,uat,newservice,IMMUTABLE,TRUE,30" >> data/ecr_repositories.csv
terraform apply -target=module.core_ecr

# Step 2: Create Kubernetes manifest
cat > Project/LearningGallery/Apps-Code_UAT/kubernetes-files/newservice.yaml << EOF
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
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
      containers:
  --region ap-southeast-1 \
  --query "imageScanFindings.findings[?severity=='CRITICAL'].{Name:name,Severity:severity,Package:attributes[?key=='package name'].value|[0]}"

# Step 2: Rebuild the image with patched base image
# Trigger Jenkins pipeline to rebuild service:
# In Jenkins: Build Now on the affected service pipeline

# Step 3: Verify new image has no CRITICAL findings
aws ecr describe-image-scan-findings \
  --repository-name cis-uat-frontend \
  --image-id imageTag=<NEW_TAG> \
  --region ap-southeast-1 \
  --query "imageScanFindings.findingSeverityCounts"

# Step 4: Update Kubernetes deployment
kubectl set image deployment/frontend \
  server=485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-frontend:<NEW_TAG>

# Step 5: Verify rollout
kubectl rollout status deployment/frontend
```

---

## 7. Backup Procedures

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

# Export secrets (encrypted)
kubectl get secrets -A -o yaml > k8s_secrets_backup.yaml
```

---

## 8. Destroy Infrastructure

**Trigger:** Environment no longer needed

```bash
# Step 1: Remove Kubernetes resources first
# (prevents orphaned LoadBalancers and ENIs)
kubectl delete -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/

# Step 2: Wait for LoadBalancer to be deprovisioned
echo "Waiting for LoadBalancer deprovisioning..."
kubectl get svc -w
# Wait until frontend-external shows no EXTERNAL-IP

# Step 3: Backup state
terraform state pull > final_state_backup_$(date +%Y%m%d_%H%M%S).tfstate

# Step 4: Destroy infrastructure
cd Project/LearningGallery/Infra-Code_UAT
terraform destroy
# Review the destroy plan carefully
# Type 'yes' to confirm

# Step 5: Destroy bootstrap (optional — preserves state history)
# WARNING: This deletes the state bucket! Only do this if 100% done
cd terraform-bootstrap
# First remove prevent_destroy lifecycle block if present
terraform destroy
```

---

## 9. Emergency Procedures

### EKS Cluster Completely Down

```bash
# Step 1: Check cluster status
aws eks describe-cluster \
  --name cis-uat-eks_main \
  --region ap-southeast-1 \
  --query "cluster.status"

# Step 2: If FAILED state, check CloudWatch logs
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/eks/cis-uat-eks_main"

# Step 3: Try terraform refresh to resync state
terraform refresh

# Step 4: If cluster is truly unrecoverable, destroy and recreate
terraform destroy -target=module.core_eks
terraform apply -target=module.core_eks

# Step 5: Reconfigure kubectl and redeploy apps
aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main
kubectl apply -f Project/LearningGallery/Apps-Code_UAT/kubernetes-files/
```

### Management EC2 Unreachable

```bash
# Step 1: Check instance status in AWS
aws ec2 describe-instance-status \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --query "InstanceStatuses[0].{InstanceState:InstanceState.Name,SystemStatus:SystemStatus.Status}"

# Step 2: Try reboot
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=vm-cis-uat-ie-tvm-01" \
  --query "Reservations[0].Instances[0].InstanceId" --output text)
aws ec2 reboot-instances --instance-ids $INSTANCE_ID

# Step 3: If still unreachable, use SSM Session Manager (no SSH needed)
aws ssm start-session --target $INSTANCE_ID

# Step 4: If completely unrecoverable, terminate and redeploy
# State is stored in Terraform — instance can be recreated
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
terraform apply -target=module.ec2_infrastructure
```
