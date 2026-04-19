# --- Core VPC Outputs ---

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.vpc.cidr_block
}

# --- Dynamic Subnet & Security Group Outputs ---

output "subnet_ids" {
  description = "Map of Subnet IDs. The keys match the exact IDs from your subnets.csv (e.g., 'web_az1')"
  # Example output: { "web_az1" = "subnet-01234abcd", "eks_az1" = "subnet-56789efgh" }
  value = { for k, v in aws_subnet.subnets : k => v.id }
}

output "sg_ids" {
  description = "Map of Security Group IDs. Keys are formatted as 'sg-[role]' (e.g., 'sg-web')"
  # Example output: { "sg-web" = "sg-01234abcd", "sg-eks" = "sg-56789efgh" }
  value = { for k, v in aws_security_group.security_group : "sg-${k}" => v.id }
}

# --- Routing & Access Control Outputs ---

output "public_route_table_id" {
  description = "The ID of the shared Public Route Table (if any public subnets exist)"
  # Safely returns the ID if it exists, or null if it doesn't
  value = length(aws_route_table.route_table_public) > 0 ? aws_route_table.route_table_public[0].id : null
}

output "private_route_table_ids" {
  description = "Map of Private Route Table IDs keyed by role (e.g., 'app', 'dbs')"
  value       = { for k, v in aws_route_table.route_table_private : k => v.id }
}

output "nacl_ids" {
  description = "Map of Network ACL IDs keyed by role (e.g., 'web', 'app')"
  value       = { for k, v in aws_network_acl.network_acl : k => v.id }
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway (if created)"
  value       = length(aws_internet_gateway.internet_gateway) > 0 ? aws_internet_gateway.internet_gateway[0].id : null
}