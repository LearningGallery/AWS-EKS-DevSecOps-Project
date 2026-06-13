# 🔧 Troubleshooting Guide

---

## 1. Authentication Errors

### Error: `No valid credential sources found`

```
Error: No valid credential sources found for AWS Provider.
```

**Solution:**
```bash
# Verify credentials are configured
aws sts get-caller-identity

# If using environment variables, check they are exported
env | grep AWS_

# Re-configure if needed
aws configure
```

---

### Error: `Error: UnauthorizedOperation`

```
Error: UnauthorizedOperation: You are not authorized to perform this operation.
```

**Solution:**
```bash
# Check what permissions your user has
aws iam get-user
aws iam list-attached-user-policies --user-name YOUR_USER

# Common missing permissions:
# - eks:CreateCluster → add AmazonEKSFullAccess
# - iam:CreateRole → add IAMFullAccess
# - kms:CreateKey → add AWSKeyManagementServicePowerUser
```

---

## 2. State Errors

### Error: `Error acquiring the state lock`

```
Error: Error acquiring the state lock
Lock Info:
  ID: abc123
  Path: core-infra/terraform.tfstate.tflock
```

**Solution:**
```bash
# First, verify no other apply is running
# Check with your team

# If confirmed no other apply is running:
aws s3 rm s3://st-cis-uat-tfstate-485950501937/core-infra/terraform.tfstate.tflock

# Or use force-unlock
terraform force-unlock abc123
```

---

### Error: `Backend configuration changed`

```
Error: Backend configuration changed
```

**Solution:**
```bash
# Reinitialize with reconfigure flag
terraform init -reconfigure
```

---

## 3. EKS Errors

### Error: `Unsupported Kubernetes version`

```
Error: InvalidParameterException: unsupported Kubernetes version
```

**Solution:**
```bash
# Check supported versions
aws eks describe-addon-versions \
  --region ap-southeast-1 \
  --query "addons[0].addonVersions[0].compatibilities[*].clusterVersion" \
  --output text

# Update eks_clusters.csv with a supported version
# e.g., change 1.31 to 1.32
```

---

### Error: Nodes not joining the cluster

**Symptoms:**
```bash
kubectl get nodes
# No resources found
```

**Solution:**
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --region ap-southeast-1 \
  --query "nodegroup.{Status:status,Health:health}"

# Common causes:
# 1. Node IAM role missing AmazonEKSWorkerNodePolicy
# 2. Subnets have no route to EKS API (check route tables)
# 3. Security groups blocking node-to-control-plane communication

# Check node group IAM role
aws iam list-attached-role-policies \
  --role-name rl-cis-uat-eks-node
# Should include: AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy,
#                 AmazonEC2ContainerRegistryReadOnly
```

---

### Error: `kubectl: connection refused`

```
The connection to the server was refused
```

**Solution:**
```bash
# Re-generate kubeconfig
aws eks update-kubeconfig \
  --region ap-southeast-1 \
  --name cis-uat-eks_main \
  --kubeconfig ~/.kube/config

# Verify cluster endpoint is accessible
aws eks describe-cluster \
  --name cis-uat-eks_main \
  --query "cluster.endpoint" \
  --output text

# Test connectivity
curl -k https://<CLUSTER_ENDPOINT>/healthz
# Expected: ok
```

---

## 4. ECR Errors

### Error: `denied: Your authorization token has expired`

```
denied: Your authorization token has expired. Reauthenticate and try again.
```

**Solution:**
```bash
# ECR tokens expire after 12 hours — refresh:
aws ecr get-login-password \
  --region ap-southeast-1 | \
docker login \
  --username AWS \
  --password-stdin \
  485950501937.dkr.ecr.ap-southeast-1.amazonaws.com
```

---

### Error: `tag-immutability: Image already exists`

```
Error: tag-immutability: An image with the tag: 'latest' already exists
```

**Solution:**
```bash
# This is by design — ECR is IMMUTABLE
# Your CI/CD pipeline uses BUILD_NUMBER-GIT_SHA tags to avoid this
# If you see this, it means a tag is being reused

# Check the tag being used
echo $IMAGE_TAG  # Should be: <build_number>-<git_sha>
# If it shows "latest", update your Jenkinsfile to use IMAGE_TAG variable
```

---

## 5. Terraform CSV Engine Errors

### Error: `Invalid for_each argument — depends on resource attributes`

```
Error: Invalid for_each argument
The "for_each" value depends on resource attributes that cannot be determined
until apply.
```

**Solution:**
```bash
# This happens when for_each value is computed (not known at plan time)
# Use -target to apply dependencies first:
terraform apply -target=module.core_iam
terraform apply -target=module.core_vpc
terraform apply  # Then apply everything
```

---

### Error: `Empty rows in CSV`

```
Error: Invalid value for variable
```

**Solution:**
```bash
# Check CSV files for empty rows or trailing newlines
cat -A data/subnets.csv | tail -5
# Remove any empty rows at the end of CSV files

# On Linux/Mac:
sed -i '/^$/d' data/subnets.csv

# On Windows (PowerShell):
(Get-Content data\subnets.csv) | Where-Object {$_ -ne ""} | Set-Content data\subnets.csv
```

---

### Error: `Index out of range` in EC2 module

```
Error: Invalid index: The given key does not identify an element in this collection value
```

**Solution:**
```bash
# Check that subnet_ids in infrastructure.csv match keys in subnets.csv
# infrastructure.csv: subnet_ids = web_az1
# subnets.csv:        id = web_az1  ← must match exactly

# Check sg_ids similarly:
# infrastructure.csv: sg_ids = sg-web
# VPC module output:  sg_ids key = "sg-web"  ← module prefixes with "sg-"
```

---

## 6. Jenkins Pipeline Errors

### Error: `docker: Got permission denied`

```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# SSH to management EC2
ssh -i learninggallery.pem ec2-user@<EC2_IP>

# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

---

### Error: `git push rejected — non-fast-forward`

```
error: failed to push some refs to 'https://github.com/...'
hint: Updates were rejected because the remote contains work that you do not have locally.
```

**Solution:**
The Jenkins pipeline handles this with `git pull --rebase` before push:
```groovy
// Already in Jenkinsfile:
git pull origin main --rebase
git push https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
```

If it persists:
```bash
# Check Jenkins credentials have push access
# Verify 'my-git-pattoken' credential in Jenkins → Manage Jenkins → Credentials
# Ensure PAT has 'repo' scope in GitHub
```

---

## 7. Debug Mode

```bash
# Enable detailed Terraform logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform_debug.log
terraform apply

# View log
tail -f terraform_debug.log

# Levels: TRACE, DEBUG, INFO, WARN, ERROR
# Start with DEBUG — TRACE is very verbose

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

---

## 8. Common AWS Service Limit Issues

| Service | Limit | Error | Solution |
|---------|-------|-------|---------|
| EKS Clusters | 100/region | `ResourceLimitExceeded` | Request limit increase in AWS Console |
| VPCs | 5/region | `VpcLimitExceeded` | Delete unused VPCs or request increase |
| Elastic IPs | 5/region | `AddressLimitExceeded` | Release unused EIPs |
| EC2 Instances | Varies by type | `InsufficientInstanceCapacity` | Try different AZ or instance type |

```bash
# Check current limits
aws service-quotas list-service-quotas \
  --service-code eks \
  --region ap-southeast-1 \
  --query "Quotas[*].{Name:QuotaName,Value:Value}"
```
