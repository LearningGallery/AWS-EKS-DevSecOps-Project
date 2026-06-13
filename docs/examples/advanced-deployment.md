# 🏗️ Advanced Deployment Example

This example shows the full production-like deployment with all modules active.

---

## Full Configuration

### Complete `data/eks_node_groups.csv` with SPOT Instances

```csv
ng_id,cluster_id,instance_types,capacity_type,min_size,max_size,desired_size,disk_size
ng_ondemand,eks_main,t3.large,ON_DEMAND,2,5,2,20
ng_spot,eks_main,t3.large;t3.xlarge;m5.large,SPOT,0,10,3,20
```

### Complete `data/infrastructure.csv` with Multiple Tiers

```csv
tier,vpc_id,project,env,zone,role,count,instance_types,ami_id,key_name,subnet_ids,sg_ids,iam_profile,vol_size,vol_type,vol_encrypt,public_ip,monitor,api_term,userdata_file,cost_center,owner
mgm,core,cis,uat,ie,tvm,1,t3.medium,ami-03c3282f979a6a9b0,learninggallery,web_az1,sg-web,ec2-profile,30,gp3,true,true,true,false,scripts/updated_install-tools.sh,012345,AbuTalha
```

### Accessing All Outputs After Deployment

```bash
# Uncomment output.tf first, then:
terraform output -json

# Expected JSON:
{
  "eks_cluster_name": {
    "value": "cis-uat-eks_main",
    "type": "string"
  },
  "eks_cluster_endpoint": {
    "value": "https://ABCDEF1234567890.gr7.ap-southeast-1.eks.amazonaws.com",
    "type": "string"
  },
  "ecr_repository_urls": {
    "value": {
      "adservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-adservice",
      "cartservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-cartservice",
      "checkoutservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-checkoutservice",
      "currencyservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-currencyservice",
      "emailservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-emailservice",
      "frontend": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-frontend",
      "loadgenerator": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-loadgenerator",
      "paymentservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-paymentservice",
      "productcatalogservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-productcatalogservice",
      "recommendationservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-recommendationservice",
      "shippingservice": "485950501937.dkr.ecr.ap-southeast-1.amazonaws.com/cis-uat-shippingservice"
    },
    "type": ["object", {...}]
  },
  "iam_role_arns": {
    "value": {
      "ec2-profile": "arn:aws:iam::485950501937:role/rl-cis-uat-ec2-profile",
      "eks-master": "arn:aws:iam::485950501937:role/rl-cis-uat-eks-master",
      "eks-node": "arn:aws:iam::485950501937:role/rl-cis-uat-eks-node"
    }
  }
}
```

### Full Kubernetes Deployment Validation

```bash
# Check all pods are running
kubectl get pods -o wide
# Expected output:
NAME                                     READY   STATUS    NODE
adservice-xxxxxxxxx-xxxxx               1/1     Running   ip-10-0-1-xxx
cartservice-xxxxxxxxx-xxxxx             1/1     Running   ip-10-0-2-xxx
checkoutservice-xxxxxxxxx-xxxxx         1/1     Running   ip-10-0-1-xxx
currencyservice-xxxxxxxxx-xxxxx         1/1     Running   ip-10-0-2-xxx
emailservice-xxxxxxxxx-xxxxx            1/1     Running   ip-10-0-1-xxx
frontend-xxxxxxxxx-xxxxx                1/1     Running   ip-10-0-2-xxx
loadgenerator-xxxxxxxxx-xxxxx           1/1     Running   ip-10-0-1-xxx
paymentservice-xxxxxxxxx-xxxxx          1/1     Running   ip-10-0-2-xxx
productcatalogservice-xxxxxxxxx-xxxxx   1/1     Running   ip-10-0-1-xxx
recommendationservice-xxxxxxxxx-xxxxx   1/1     Running   ip-10-0-2-xxx
redis-cart-xxxxxxxxx-xxxxx              1/1     Running   ip-10-0-1-xxx
shippingservice-xxxxxxxxx-xxxxx         1/1     Running   ip-10-0-2-xxx

# Get frontend external URL
kubectl get svc frontend-external
# NAME               TYPE           CLUSTER-IP     EXTERNAL-IP                         PORT(S)
# frontend-external  LoadBalancer   172.20.x.x     xxxx.ap-southeast-1.elb.amazonaws.com  80:xxxxx/TCP

# Access the application
curl http://xxxx.ap-southeast-1.elb.amazonaws.com
```
