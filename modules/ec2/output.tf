output "instance_ids" {
  description = "List of EC2 Instance IDs created in this tier"
  # Example output: ["i-0123456789abcdef0", "i-0abcdef1234567890"]
  value = aws_instance.instances[*].id
}

output "private_ips" {
  description = "List of private IP addresses assigned to the instances"
  # Example output: ["10.0.1.15", "10.0.2.45"]
  value = aws_instance.instances[*].private_ip
}

output "arns" {
  description = "List of ARNs for the created instances"
  value       = aws_instance.instances[*].arn
}

output "instance_names" {
  description = "List of the dynamically generated Names (useful for dynamic DNS or load balancer targets)"
  # Example output: ["vm-cis-prd-ia-web-01", "vm-cis-prd-ia-web-02"]
  value = aws_instance.instances[*].tags["Name"]
}