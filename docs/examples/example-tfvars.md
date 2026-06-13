# 📝 Example Variable Files

---

## Root Module `terraform.tfvars`

The root module has only one variable (`aws_region`), so `terraform.tfvars` is minimal:

```hcl
# Project/LearningGallery/Infra-Code_UAT/terraform.tfvars
# (This file is in .gitignore — create locally)

aws_region = "ap-southeast-1"
```

---

## Bootstrap Module `terraform.tfvars`

```hcl
# Project/LearningGallery/Infra-Code_UAT/terraform-bootstrap/terraform.tfvars

aws_region   = "ap-southeast-1"
project_code = "cis"
environment  = "uat"

common_tags = {
  ManagedBy   = "Terraform-Bootstrap"
  Role        = "Infrastructure-State"
  Environment = "uat"
  Project     = "cis"
}
```

---

## Infrastructure CSV Examples

### Minimal `vpcs.csv` (Single VPC)

```csv
vpc_id,project,env,cidr_block,network_zone
core,cis,uat,10.0.0.0/16,ia
```

### Full `subnets.csv` (4 Subnets, 2 AZs)

```csv
id,vpc_id,cidr_block,az,is_public,role
web_az1,core,10.0.1.0/24,ap-southeast-1a,true,web
web_az2,core,10.0.2.0/24,ap-southeast-1b,true,web
eks_az1,core,10.0.10.0/24,ap-southeast-1a,false,eks
eks_az2,core,10.0.11.0/24,ap-southeast-1b,false,eks
```

### Full `iam_roles.csv` (3 Roles)

```csv
role_id,project,env,trusted_service,managed_policies,custom_policy_file,create_instance_profile,eks_access_policy
ec2-profile,cis,uat,ec2.amazonaws.com,arn:aws:iam::aws:policy/AdministratorAccess;arn:aws:iam::aws:policy/AmazonEKSClusterPolicy,policies/eks_custom_policy.json,true,arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy
eks-master,cis,uat,eks.amazonaws.com,arn:aws:iam::aws:policy/AmazonEKSClusterPolicy;arn:aws:iam::aws:policy/AmazonEKSVPCResourceController,,false,
eks-node,cis,uat,ec2.amazonaws.com,arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy;arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy;arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly,policies/eks_autoscaler_policy.json,true,
```

### Full `eks_clusters.csv`

```csv
cluster_id,project,environment,k8s_version,vpc_id,subnet_ids,endpoint_private,endpoint_public,cluster_iam_role,node_iam_role,cluster_sg
eks_main,cis,uat,1.31,core,web_az1;web_az2,true,true,eks-master,eks-node,web
```

### Full `eks_node_groups.csv`

```csv
ng_id,cluster_id,instance_types,capacity_type,min_size,max_size,desired_size,disk_size
ng_app,eks_main,t3.large,ON_DEMAND,2,10,3,20
```

### Full `ecr_repositories.csv` (All 11 Services)

```csv
project,environment,service_name,image_mutability,scan_on_push,max_images
cis,uat,adservice,IMMUTABLE,TRUE,30
cis,uat,cartservice,IMMUTABLE,TRUE,30
cis,uat,checkoutservice,IMMUTABLE,TRUE,30
cis,uat,currencyservice,IMMUTABLE,TRUE,30
cis,uat,emailservice,IMMUTABLE,TRUE,30
cis,uat,frontend,IMMUTABLE,TRUE,30
cis,uat,loadgenerator,IMMUTABLE,TRUE,30
cis,uat,paymentservice,IMMUTABLE,TRUE,30
cis,uat,productcatalogservice,IMMUTABLE,TRUE,30
cis,uat,recommendationservice,IMMUTABLE,TRUE,30
cis,uat,shippingservice,IMMUTABLE,TRUE,30
```

---

## Expected `terraform plan` Output (Summary)

```
Terraform will perform the following actions:

  # module.core_ecr.aws_ecr_lifecycle_policy.cleanup["adservice"] will be created
  # module.core_ecr.aws_ecr_lifecycle_policy.cleanup["cartservice"] will be created
  # ... (11 total lifecycle policies)

  # module.core_ecr.aws_ecr_repository.registry["adservice"] will be created
  # module.core_ecr.aws_ecr_repository.registry["cartservice"] will be created
  # ... (11 total ECR repos)

  # module.core_eks["eks_main"].aws_eks_cluster.main will be created
  # module.core_eks["eks_main"].aws_eks_node_group.nodes["ng_app"] will be created
  # module.core_eks["eks_main"].aws_kms_key.eks_secrets will be created

  # module.core_iam.aws_iam_instance_profile.profile["ec2-profile"] will be created
  # module.core_iam.aws_iam_instance_profile.profile["eks-node"] will be created
  # module.core_iam.aws_iam_policy.custom_policy["ec2-profile"] will be created
  # module.core_iam.aws_iam_policy.custom_policy["eks-node"] will be created
  # module.core_iam.aws_iam_role.role["ec2-profile"] will be created
  # module.core_iam.aws_iam_role.role["eks-master"] will be created
  # module.core_iam.aws_iam_role.role["eks-node"] will be created

  # module.core_vpc["core"].aws_internet_gateway.internet_gateway[0] will be created
  # module.core_vpc["core"].aws_network_acl.network_acl["web"] will be created
  # module.core_vpc["core"].aws_route_table.route_table_public[0] will be created
  # module.core_vpc["core"].aws_route.route["pub-0"] will be created
  # module.core_vpc["core"].aws_security_group.security_group["web"] will be created
  # module.core_vpc["core"].aws_security_group.security_group["eks"] will be created
  # module.core_vpc["core"].aws_security_group_rule.security_group_rule["web-ingress-tcp-443-443-0.0.0.0/0"] will be created
  # ... (16+ SG rules total)
  # module.core_vpc["core"].aws_subnet.subnets["web_az1"] will be created
  # module.core_vpc["core"].aws_subnet.subnets["web_az2"] will be created
  # module.core_vpc["core"].aws_subnet.subnets["eks_az1"] will be created
  # module.core_vpc["core"].aws_subnet.subnets["eks_az2"] will be created
  # module.core_vpc["core"].aws_vpc.vpc will be created

  # module.ec2_infrastructure["mgm"].aws_instance.instances[0] will be created

  # aws_iam_openid_connect_provider.eks["eks_main"] will be created
  # aws_eks_access_entry.ec2_profile_access will be created
  # aws_eks_access_policy_association.ec2_profile_admin will be created

Plan: 54 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee
to take exactly these actions if you run "terraform apply" now.
```

---

## Expected `terraform apply` Output (Last Lines)

```
Apply complete! Resources: 54 added, 0 changed, 0 destroyed.

Outputs:

(Note: Uncomment output.tf to see outputs here)

To configure kubectl:
  aws eks update-kubeconfig --region ap-southeast-1 --name cis-uat-eks_main
```
