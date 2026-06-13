# 🤝 Contributing Guidelines

Thank you for considering contributing to the AWS EKS DevSecOps Platform!

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Code Style Guide](#code-style-guide)
- [Testing Requirements](#testing-requirements)
- [Documentation Standards](#documentation-standards)

---

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on technical merit in code reviews
- Help others learn — this is a learning-focused project

---

## How to Contribute

### 1. Report Issues

```
Use GitHub Issues to report:
- Bugs in Terraform code
- Documentation errors
- Security vulnerabilities (use private disclosure)
- Feature requests
```

### 2. Contribute Code

```bash
# Fork the repository
# Clone your fork
git clone https://github.com/YOUR_USERNAME/AWS-EKS-DevSecOps-Project.git

# Create a feature branch
git checkout -b feat/add-nat-gateway

# Make changes
# ...

# Commit with conventional commit format
git commit -m "feat: add NAT Gateway for private subnet egress"

# Push and create Pull Request
git push origin feat/add-nat-gateway
```

---

## Development Setup

```bash
# Install required tools
# 1. Terraform >= 1.12
wget https://releases.hashicorp.com/terraform/1.12.0/terraform_1.12.0_linux_amd64.zip
unzip terraform_1.12.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# 2. AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# 3. Trivy (security scanning)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# 4. Pre-commit hooks (recommended)
pip install pre-commit
pre-commit install
```

### Pre-commit Configuration (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint
      - id: terraform_trivy
```

---

## Pull Request Process

### Before Submitting

```bash
# 1. Format all Terraform code
terraform fmt -recursive

# 2. Validate configuration
terraform validate

# 3. Run security scan
trivy fs --scanners misconfig --severity HIGH,CRITICAL .

# 4. Check for secrets
git diff --cached | grep -E "(password|secret|key|token)" | grep -v ".gitignore"

# 5. Update documentation if modules changed
# Edit docs/04-MODULE-REFERENCE.md
# Edit docs/05-VARIABLES-GUIDE.md
```

### PR Checklist

```
[ ] terraform fmt -recursive passes
[ ] terraform validate passes
[ ] trivy scan passes (no CRITICAL/HIGH misconfigs)
[ ] No secrets or credentials in code
[ ] CSV changes validated (IDs consistent across files)
[ ] Documentation updated for any module changes
[ ] CHANGELOG.md updated
[ ] Commit messages follow conventional commits format
[ ] PR description explains the change and motivation
```

### Conventional Commit Format

```
feat:     New feature or capability
fix:      Bug fix
security: Security improvement
docs:     Documentation only
chore:    Maintenance, dependency updates
refactor: Code refactoring (no functional change)
test:     Adding or updating tests
ci:       CI/CD pipeline changes

Examples:
feat: add NAT Gateway module for private subnet egress
fix: correct subnet CIDR overlap in subnets.csv
security: restrict SSH SG rule to office CIDR
docs: add IRSA example to security guide
chore: update AWS provider to 5.40
```

---

## Code Style Guide

### Terraform Style

```hcl
# 1. Use 2-space indentation
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "vp-${local.base}-01"
  }
}

# 2. Group related arguments together
resource "aws_instance" "instances" {
  # Identification
  ami           = var.ami_id
  instance_type = element(var.instance_types, count.index)

  # Network
  subnet_id                   = element(var.subnet_ids, count.index)
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = var.associate_public_ip_address

  # Security
  iam_instance_profile = var.iam_instance_profile
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Storage
  root_block_device {
    volume_size = var.root_volume_size
    encrypted   = var.encrypted
  }

  # Tags last
  tags = {
    Name = "vm-${var.project_code}-${var.environment}-${var.network_zone}-${var.role}-${format("%02d", count.index + 1)}"
  }
}

# 3. Always add descriptions to variables
variable "cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS control plane"
  type        = string
}

# 4. Always add descriptions to outputs
output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}
```

### CSV Style

```csv
# 1. Always include header row
# 2. No spaces after commas
# 3. No trailing commas
# 4. No empty rows at end of file
# 5. Use lowercase for environment values (uat, dev, prd)
# 6. Use semicolons for list values within a field

# Good:
vpc_id,project,env,cidr_block,network_zone
core,cis,uat,10.0.0.0/16,ia

# Bad:
vpc_id, project, env, cidr_block, network_zone
core, cis, UAT, 10.0.0.0/16, ia
```

---

## Adding a New Module

```bash
# 1. Create module directory
mkdir -p modules/my_new_module

# 2. Create required files
touch modules/my_new_module/main.tf
touch modules/my_new_module/variables.tf
touch modules/my_new_module/outputs.tf

# 3. Follow module template:
cat > modules/my_new_module/variables.tf << 'EOF'
variable "project_code" {
  description = "3-character project code"
  type        = string
}

variable "environment" {
  description = "Environment tier (dev/uat/prd)"
  type        = string
}
EOF

# 4. Reference in main.tf
# Add module call in Infra-Code_UAT/main.tf

# 5. Add CSV data file if needed
touch Project/LearningGallery/Infra-Code_UAT/data/my_new_resource.csv

# 6. Document in docs/04-MODULE-REFERENCE.md
# 7. Document variables in docs/05-VARIABLES-GUIDE.md
# 8. Document outputs in docs/06-OUTPUTS-GUIDE.md
```

---

## Testing Requirements

### Required Tests

```bash
# 1. Terraform syntax
terraform validate
# Must pass with no errors

# 2. Terraform formatting
terraform fmt -check -recursive
# Must pass with no changes

# 3. Security scanning
trivy fs --scanners misconfig --severity HIGH,CRITICAL --exit-code 1 .
# Must pass with no HIGH or CRITICAL findings

# 4. Dry run plan
terraform plan
# Must show expected resources with no errors
# Must not show unexpected destroy operations
```

### Recommended Tests

```bash
# 5. Checkov policy scan
checkov -d . --framework terraform

# 6. TFLint linting
tflint --recursive

# 7. Cost estimation
infracost breakdown --path .
```

---

## Documentation Standards

When contributing, update documentation if you:

| Change | Documents to Update |
|--------|-------------------|
| Add new variable | `docs/05-VARIABLES-GUIDE.md` |
| Add new output | `docs/06-OUTPUTS-GUIDE.md` |
| Add new module | `docs/03-MODULES-OVERVIEW.md`, `docs/04-MODULE-REFERENCE.md` |
| Add new CSV column | `docs/05-VARIABLES-GUIDE.md` |
| Fix a known issue | `docs/15-KNOWN-ISSUES.md` |
| Add new feature | `docs/16-ROADMAP.md` (move from roadmap to changelog) |
| Architecture change | `docs/02-ARCHITECTURE.md`, `docs/adr/ADR-NNN-*.md` |
