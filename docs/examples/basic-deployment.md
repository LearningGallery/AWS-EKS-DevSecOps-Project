# 🚀 Basic Deployment Example

This example shows the minimum configuration needed to deploy the core infrastructure.

---

## Minimal Configuration

### Step 1: Minimal `data/vpcs.csv`

```csv
vpc_id,project,env,cidr_block,network_zone
core,cis,uat,10.0.0.0/16,ia
```

### Step 2: Minimal `data/subnets.csv`

```csv
id,vpc_id,cidr_block,az,is_public,role
web_az1,core,10.0.1.0/24,ap-southeast-1a,true,web
```

### Step 3: Minimal `data/sg_rules.csv`

```csv
vpc_id,sg_role,type,from_port,to_port,protocol,source_type,source,description
core,web,ingress,443,443,tcp,cidr,0.0.0.0/0,Allow HTTPS
core,web,egress,443,443,tcp,cidr,0.0.0.0/0,Allow HTTPS out
```

### Step 4: Minimal `data/route_rules.csv`

```csv
vpc_id,route_table_role,destination_cidr,target_type
core,pub,0.0.0.0/0,igw
```

### Step 5: Minimal `data/iam_roles.csv`

```csv
role_id,project,env,trusted_service,managed_policies,custom_policy_file,create_instance_profile,eks_access_policy
ec2-profile,cis,uat,ec2.amazonaws.com,arn:aws:iam::aws:policy/AmazonEC2FullAccess,,true,
```

### Step 6: No EC2 Instances (empty `data/infrastructure.csv`)

```csv
tier,vpc_id,project,env,zone,role,count,instance_types,ami_id,key_name,subnet_ids,sg_ids,iam_profile,vol_size,vol_type,vol_encrypt,public_ip,monitor,api_term,userdata_file,cost_center,owner
```

### Step 7: Deploy VPC Only

```bash
# Apply only VPC and IAM modules
terraform apply \
  -target=module.core_iam \
  -target=module.core_vpc
```

### Expected Output

```
Plan: 14 to add, 0 to change, 0 to destroy.

+ module.core_iam.aws_iam_role.role["ec2-profile"]
+ module.core_iam.aws_iam_instance_profile.profile["ec2-profile"]
+ module.core_vpc["core"].aws_vpc.vpc
+ module.core_vpc["core"].aws_internet_gateway.internet_gateway[0]
+ module.core_vpc["core"].aws_subnet.subnets["web_az1"]
+ module.core_vpc["core"].aws_route_table.route_table_public[0]
+ module.core_vpc["core"].aws_route_table_association.route_table_association["web_az1"]
+ module.core_vpc["core"].aws_route.route["pub-0"]
+ module.core_vpc["core"].aws_security_group.security_group["web"]
+ module.core_vpc["core"].aws_security_group_rule.security_group_rule["web-ingress-tcp-443-443-0.0.0.0/0"]
+ module.core_vpc["core"].aws_security_group_rule.security_group_rule["web-egress-tcp-443-443-0.0.0.0/0"]
+ module.core_vpc["core"].aws_network_acl.network_acl["web"]
...

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```
