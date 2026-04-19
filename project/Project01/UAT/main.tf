locals {
  # 1. Read all CSVs
  raw_vpcs    = csvdecode(file("${path.module}/data/vpcs.csv"))
  raw_iam     = csvdecode(file("${path.module}/data/iam_roles.csv"))
  raw_subnets = csvdecode(file("${path.module}/data/subnets.csv"))
  raw_sg      = csvdecode(file("${path.module}/data/sg_rules.csv"))
  raw_nacl    = csvdecode(file("${path.module}/data/nacl_rules.csv"))
  raw_route   = csvdecode(file("${path.module}/data/route_rules.csv"))
  raw_ec2     = csvdecode(file("${path.module}/data/infrastructure.csv"))
  raw_ecr     = csvdecode(file("${path.module}/data/ecr_repos.csv"))

  # 2. Transform into Maps
  vpc_map     = { for r in local.raw_vpcs : r.vpc_id => r }
  iam_map     = { for r in local.raw_iam : r.role_id => { trusted_service = r.trusted_service, managed_policies = split(";", r.managed_policies) } }
  subnet_map  = { for r in local.raw_subnets : r.id => { vpc_id = r.vpc_id, cidr_block = r.cidr_block, az = r.az, is_public = tobool(r.is_public), role = r.role } }
  ec2_map     = { for r in local.raw_ec2 : r.tier => r }
  ecr_map     = { for r in local.raw_ecr : r.repo_name => { repo_name = r.repo_name, mutability = r.mutability, scan_on_push = tobool(r.scan_on_push) } }

}

/* # ---------------------------------------------------------
# IAM Engine
# ---------------------------------------------------------
module "core_iam" {
  source       = "../../../modules/iam"
  project_code = var.project_code
  environment  = var.environment
  roles        = local.iam_map
}
*/

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

/*
# ---------------------------------------------------------
# EC2 Engine
# ---------------------------------------------------------
module "ec2_infrastructure" {
  source   = "./modules/ec2_tier"
  for_each = local.ec2_map

  project_code   = local.project
  environment    = local.env
  network_zone   = local.zone
  role           = each.value.role
  instance_count = tonumber(each.value.count)
  instance_types = split(";", each.value.instance_types)
  ami_id         = each.value.ami_id

  # Dynamic Lookups from VPC Module output
  subnet_ids             = [for sid in split(";", each.value.subnet_ids) : module.core_vpc.subnet_ids[sid]]
  vpc_security_group_ids = [for sg in split(";", each.value.sg_ids) : module.core_vpc.sg_ids[sg]]
  
  # Dynamic Lookup from IAM Module output
  iam_instance_profile = each.value.iam_profile != "" ? module.core_iam.instance_profile_names[each.value.iam_profile] : null

  root_volume_size = tonumber(each.value.vol_size)
  root_volume_type = each.value.vol_type
  encrypted        = tobool(each.value.vol_encrypt)
  user_data        = each.value.userdata_file != "" ? file("${path.module}/${each.value.userdata_file}") : null
}

# ---------------------------------------------------------
# ECR Engine
# ---------------------------------------------------------
module "core_ecr" {
  source       = "./modules/ecr_base"
  project_code = local.project
  environment  = local.env
  repositories = local.ecr_map
}

# ---------------------------------------------------------
# EKS Engine
# ---------------------------------------------------------
module "core_eks" {
  source       = "./modules/eks_base"
  project_code = local.project
  environment  = local.env
  network_zone = local.zone

  # Pass only the subnets labeled for EKS
  subnet_ids = [for k, v in module.core_vpc.subnet_ids : v if length(regexall("^eks_", k)) > 0]
  
  # Fetch ARNs explicitly from the IAM module
  cluster_role_arn = module.core_iam.role_arns["eks_cluster_role"]
  node_role_arn    = module.core_iam.role_arns["eks_node_role"]
}
*/
