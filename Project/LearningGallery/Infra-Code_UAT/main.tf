locals {
  # 1. Read all CSVs
  raw_vpcs          = csvdecode(file("${path.module}/data/vpcs.csv"))
  raw_iam           = csvdecode(file("${path.module}/data/iam_roles.csv"))
  raw_subnets       = csvdecode(file("${path.module}/data/subnets.csv"))
  raw_sg            = csvdecode(file("${path.module}/data/sg_rules.csv"))
  raw_nacl          = csvdecode(file("${path.module}/data/nacl_rules.csv"))
  raw_route         = csvdecode(file("${path.module}/data/route_rules.csv"))
  raw_ec2           = csvdecode(file("${path.module}/data/infrastructure.csv"))
  raw_ecr           = csvdecode(file("${path.module}/data/ecr_repositories.csv"))
  raw_eks_clusters  = csvdecode(file("${path.module}/data/eks_clusters.csv"))
  raw_eks_nodes     = csvdecode(file("${path.module}/data/eks_node_groups.csv"))

  # 2. Transform into Maps
  vpc_map     = { for r in local.raw_vpcs : r.vpc_id => r }
  iam_map     = { for r in local.raw_iam : r.role_id => { project = r.project, env = r.env, trusted_service = r.trusted_service, managed_policies = r.managed_policies, custom_policy_file = r.custom_policy_file, create_instance_profile = tobool(r.create_instance_profile) } }
  subnet_map  = { for r in local.raw_subnets : r.id => { vpc_id = r.vpc_id, cidr_block = r.cidr_block, az = r.az, is_public = tobool(r.is_public), role = r.role } }
  ec2_map     = { for r in local.raw_ec2 : r.tier => r }
  ecr_map     = { for r in local.raw_ecr : r.service_name => { project = r.project, environment = r.environment, repo_name = r.service_name, mutability = r.image_mutability, scan_on_push = tobool(lower(r.scan_on_push)), max_images = tonumber(r.max_images) } }
  eks_cluster_map = { for r in local.raw_eks_clusters : r.cluster_id => { project = r.project, environment = r.environment, cluster_id = r.cluster_id, k8s_version = r.k8s_version, vpc_id = r.vpc_id, subnet_ids = split(";", r.subnet_ids), endpoint_private = tobool(r.endpoint_private), endpoint_public = tobool(r.endpoint_public), cluster_iam_role = r.cluster_iam_role, node_iam_role = r.node_iam_role } }
  eks_node_map = { for r in local.raw_eks_nodes : r.ng_id => { cluster_id = r.cluster_id, instance_types = split(";", r.instance_types), capacity_type = r.capacity_type, min_size = tonumber(r.min_size), max_size = tonumber(r.max_size), desired_size = tonumber(r.desired_size), disk_size = tonumber(r.disk_size) } }
}

# ---------------------------------------------------------
# IAM Engine
# ---------------------------------------------------------
module "core_iam" {
  source = "../../../modules/iam"
  roles  = local.iam_map
}

# ---------------------------------------------------------
# VPC Engine
# ---------------------------------------------------------
module "core_vpc" {
  source       = "../../../modules/vpc"
  for_each     = local.vpc_map
  project_code = each.value.project
  environment  = each.value.env
  network_zone = each.value.network_zone
  vpc_cidr     = each.value.cidr_block
  subnets      = { for k, v in local.subnet_map : k => v if v.vpc_id == each.key }
  sg_rules     = [ for r in local.raw_sg : r if r.vpc_id == each.key ]
  nacl_rules   = [ for r in local.raw_nacl : r if r.vpc_id == each.key ]
  route_rules  = [ for r in local.raw_route : r if r.vpc_id == each.key ]
}

# ---------------------------------------------------------
# EC2 Engine
# ---------------------------------------------------------
module "ec2_infrastructure" {
  source   = "../../../modules/ec2"
  for_each = local.ec2_map

  project_code   = each.value.project
  environment    = each.value.env
  network_zone   = each.value.zone
  role           = each.value.role
  instance_count = tonumber(each.value.count)
  instance_types = split(";", each.value.instance_types)
  ami_id         = each.value.ami_id
  key_name      = each.value.key_name
  
  # Implicit Dependency: Network
  # Looks up the specific VPC map first, then grabs the correct subnet/sg ID
  subnet_ids             = [for sid in split(";", each.value.subnet_ids) : module.core_vpc[each.value.vpc_id].subnet_ids[sid]]
  vpc_security_group_ids = [for sg in split(";", each.value.sg_ids) : module.core_vpc[each.value.vpc_id].sg_ids[sg]]
  
  # Implicit Dependency: Identity
  # Waits for the IAM module to generate the profile before assigning
  iam_instance_profile = each.value.iam_profile != "" ? module.core_iam.instance_profile_names[each.value.iam_profile] : null

  root_volume_size = tonumber(each.value.vol_size)
  root_volume_type = each.value.vol_type
  encrypted        = tobool(each.value.vol_encrypt)
  associate_public_ip_address = tobool(each.value.public_ip)
  # Safe lookup for the bootstrap script
  user_data = each.value.userdata_file != "" ? file("${path.module}/${each.value.userdata_file}") : null
}

# ---------------------------------------------------------
# ECR Engine
# ---------------------------------------------------------
module "core_ecr" {
  source       = "../../../modules/ecr"
  repositories = local.ecr_map
}

# ---------------------------------------------------------
# EKS Engine
# ---------------------------------------------------------
module "core_eks" {
  source   = "../../../modules/eks"
  for_each = local.eks_cluster_map

  project          = each.value.project
  environment      = each.value.environment
  cluster_name     = each.value.cluster_id
  k8s_version      = each.value.k8s_version
  
  # Dynamic Network Resolution! Looks up actual subnet IDs from the VPC module
  subnet_ids       = [for sid in each.value.subnet_ids : module.core_vpc[each.value.vpc_id].subnet_ids[sid]]
  
  endpoint_private = each.value.endpoint_private
  endpoint_public  = each.value.endpoint_public

  # Injects the ARNs dynamically from your IAM module based on the trusted service relationship defined in the CSV
  cluster_role_arn = module.core_iam.role_arns[each.value.cluster_iam_role]
  node_role_arn    = module.core_iam.role_arns[each.value.node_iam_role]

  # Pass only the node groups that belong to THIS specific cluster
  node_groups = { for k, v in local.eks_node_map : k => v if v.cluster_id == each.key }
}

# ---------------------------------------------------------
# EKS OIDC Providers (Zero Trust IRSA)
# ---------------------------------------------------------
# 1. Dynamically fetch the TLS certificates from the newly created EKS clusters
data "tls_certificate" "eks" {
  for_each = module.core_eks
  
  url      = each.value.oidc_issuer_url
}

# 2. Create the IAM OIDC Providers for Least Privilege Pod Access
resource "aws_iam_openid_connect_provider" "eks" {
  for_each        = module.core_eks
  
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[each.key].certificates[0].sha1_fingerprint]
  url             = each.value.oidc_issuer_url
}