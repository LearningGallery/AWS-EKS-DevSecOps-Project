resource "aws_instance" "instances" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = element(var.instance_types, count.index)
  key_name                    = var.key_name != "" ? var.key_name : null
  subnet_id                   = element(var.subnet_ids, count.index)
  vpc_security_group_ids      = var.vpc_security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = var.user_data
  user_data_replace_on_change = true
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    encrypted             = var.encrypted
    tags = { Name = "vol-${var.project_code}-${var.environment}-${var.network_zone}-${var.role}-${format("%02d", count.index + 1)}" }
  }
  associate_public_ip_address = var.associate_public_ip_address
  tags = { Name = "vm-${var.project_code}-${var.environment}-${var.network_zone}-${var.role}-${format("%02d", count.index + 1)}" }
  lifecycle { ignore_changes = [ami] }
}