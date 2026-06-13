# 💰 Cost Optimization Guide

---

## 1. Estimated Monthly Costs (UAT)

| Resource | Specification | Est. Cost/Month |
|----------|--------------|-----------------|
| EKS Control Plane | 1 cluster | ~$73 |
| EC2 Worker Nodes | 3x t3.large (ON_DEMAND) | ~$180 |
| EC2 Management VM | 1x t3.medium | ~$30 |
| ECR Storage | 11 repos × ~500MB | ~$5 |
| S3 State Bucket | < 1MB | ~$0.01 |
| KMS Key | 1 key | ~$1 |
| Data Transfer | Moderate | ~$5-10 |
| **Total** | | **~$294-299/month** |

> 💡 The EKS control plane ($73/month) is a fixed cost. Biggest variable cost is EC2 worker nodes.

---

## 2. Cost Optimization Strategies

### Strategy 1: Use SPOT Instances for Non-Prod

```csv
# data/eks_node_groups.csv — switch to SPOT:
ng_id,cluster_id,instance_types,capacity_type,min_size,max_size,desired_size,disk_size
ng_spot,eks_main,t3.large;t3.xlarge;t2.large,SPOT,1,10,2,20
```

**Savings:** 60-70% vs ON_DEMAND → ~$108-126/month for nodes

> ⚠️ SPOT instances can be interrupted with 2-minute warning. Use for stateless workloads only.

### Strategy 2: Reduce Node Count Off-Hours

```bash
# Scale down to minimum nodes during off-hours (e.g., nights/weekends)
aws eks update-nodegroup-config \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --scaling-config minSize=0,maxSize=10,desiredSize=0 \
  --region ap-southeast-1

# Scale back up for work hours
aws eks update-nodegroup-config \
  --cluster-name cis-uat-eks_main \
  --nodegroup-name cis-uat-ng_app \
  --scaling-config minSize=2,maxSize=10,desiredSize=3 \
  --region ap-southeast-1
```

**Savings:** 60% cost reduction (12 hours/day × 5 days/week) → ~$108/month

### Strategy 3: Stop Management EC2 Off-Hours

```bash
# Stop management instance when not in use
aws ec2 stop-instances \
  --instance-ids <INSTANCE_ID> \
  --region ap-southeast-1

# Start when needed
aws ec2 start-instances \
  --instance-ids <INSTANCE_ID> \
  --region ap-southeast-1
```

**Savings:** ~$20-25/month (50% off-hours)

### Strategy 4: Right-Size Node Instances

```bash
# Check actual resource utilization
kubectl top nodes
kubectl top pods

# If utilization < 30%, downsize:
# Change t3.large → t3.medium in eks_node_groups.csv
# Savings: ~$90/month
```

### Strategy 5: ECR Lifecycle Policies

Already implemented — keeps only last 30 images per repo:

```hcl
# Each image is ~200-500MB
# 30 images × 11 repos × 350MB avg = ~115GB max
# Cost at $0.10/GB = ~$11.50/month max
# Without lifecycle: unlimited growth
```

---

## 3. Cost Monitoring

```bash
# View current month costs by service
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query "ResultsByTime[0].Groups[*].{Service:Keys[0],Cost:Metrics.UnblendedCost.Amount}" \
  --output table

# Set up a billing alert
aws budgets create-budget \
  --account-id 485950501937 \
  --budget '{
    "BudgetName": "EKS-UAT-Monthly",
    "BudgetLimit": {"Amount": "350", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[{
    "Notification": {
      "NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN",
      "Threshold": 80
    },
    "Subscribers": [{
      "SubscriptionType": "EMAIL",
      "Address": "abutalha3005@gmail.com"
    }]
  }]'
```

---

## 4. Cost Tagging Strategy

All resources are tagged for cost allocation:

```hcl
# Current tags applied:
{
  Environment = "uat"
  Project     = "cis"
  Service     = "<service_name>"
  ManagedBy   = "Terraform"
}
```

**To enable Cost Allocation Tags:**
```bash
# In AWS Console: Billing → Cost Allocation Tags → Activate
# Tags to activate: Environment, Project, ManagedBy
```

---

## 5. Preview Costs Before Applying

```bash
# Use infracost for cost estimation before apply
# Install: https://www.infracost.io/docs/

infracost breakdown \
  --path Project/LearningGallery/Infra-Code_UAT \
  --terraform-plan-flags="-var=aws_region=ap-southeast-1"

# Expected output:
# Name                             Monthly Qty  Unit   Monthly Cost
# aws_eks_cluster.main                      1  hours        $73.00
# aws_instance.instances[0]               730  hours        $30.37
# aws_eks_node_group.nodes["ng_app"]      730  hours       $180.00
# ...
# TOTAL                                                    $294.37
```