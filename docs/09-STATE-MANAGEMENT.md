# 🗄️ State Management

---

## 1. What Is Terraform State?

Terraform state is a **JSON file that maps your HCL code to real AWS resources**. Think of it as Terraform's memory — it knows that `module.core_vpc["core"].aws_vpc.vpc` corresponds to `vpc-0a1b2c3d4e5f67890` in AWS.

Without state, Terraform cannot:
- Know what already exists
- Calculate what needs to change
- Safely update existing resources

---

## 2. State Architecture

This project uses **two-level state management**:

```
Level 1: Bootstrap State (local)
  Location: terraform-bootstrap/terraform.tfstate
  Purpose:  Tracks the S3 bucket and DynamoDB table
  Type:     Local (intentional — it creates the remote backend)

Level 2: Core Infrastructure State (remote)
  Location: s3://st-cis-uat-tfstate-485950501937/core-infra/terraform.tfstate
  Purpose:  Tracks all infrastructure resources
  Type:     Remote S3 with native lock file
```

---

## 3. Remote State Backend Configuration

```hcl
# Project/LearningGallery/Infra-Code_UAT/backend.tf
terraform {
  backend "s3" {
    bucket       = "st-cis-uat-tfstate-485950501937"
    key          = "core-infra/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true   # Native S3 locking (Terraform 1.10+)
    encrypt      = true   # AES256 encryption
  }
}
```

### Why S3 Backend?

| Feature | Local State | S3 Remote State |
|---------|-------------|-----------------|
| Team collaboration | ❌ Conflicts | ✅ Shared |
| State locking | ❌ None | ✅ Via lock file |
| State history | ❌ No versioning | ✅ S3 versioning |
| Encryption | ❌ Plain text | ✅ AES256 |
| Backup | ❌ Manual | ✅ S3 durability |

---

## 4. State Locking

This project uses **native S3 locking** (Terraform >= 1.10):

```hcl
use_lockfile = true
# Creates: s3://bucket/core-infra/terraform.tfstate.tflock
# Prevents concurrent applies from corrupting state
```

**How locking works:**
1. `terraform apply` starts → creates `.tflock` object in S3
2. Another `terraform apply` starts → sees lock → **waits or errors**
3. First apply completes → deletes `.tflock` object
4. Second apply proceeds

### Force Unlock (Emergency Use Only)

```bash
# List current locks
aws s3 ls s3://st-cis-uat-tfstate-485950501937/core-infra/

# If you see terraform.tfstate.tflock and apply is stuck:
terraform force-unlock <LOCK_ID>

# OR manually delete the lock file
aws s3 rm s3://st-cis-uat-tfstate-485950501937/core-infra/terraform.tfstate.tflock
```

> ⚠️ **WARNING:** Only force-unlock if you are certain no other `terraform apply` is running. Forcing unlock while another apply is running **will corrupt state**.

---

## 5. State Commands Reference

```bash
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show module.core_vpc["core"].aws_vpc.vpc

# Move a resource to a new address (rename)
terraform state mv \
  module.core_eks["eks_main"].aws_eks_cluster.main \
  module.core_eks["eks_main"].aws_eks_cluster.cluster

# Remove a resource from state (does NOT delete from AWS)
terraform state rm module.ec2_infrastructure["mgm"].aws_instance.instances[0]

# Pull current remote state to local file
terraform state pull > current_state_backup.tfstate

# Push a local state file to remote (dangerous — use with caution)
terraform state push current_state_backup.tfstate

# Refresh state to match real infrastructure
terraform refresh
```

---

## 6. State Backup and Recovery

### Automatic Backup via S3 Versioning

The state bucket has versioning enabled:

```bash
# List all state versions
aws s3api list-object-versions \
  --bucket st-cis-uat-tfstate-485950501937 \
  --prefix core-infra/terraform.tfstate \
  --query "Versions[*].{VersionId:VersionId,LastModified:LastModified,IsLatest:IsLatest}"

# Restore a previous version
aws s3api get-object \
  --bucket st-cis-uat-tfstate-485950501937 \
  --key core-infra/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup

# Push the backup as current state
terraform state push terraform.tfstate.backup
```

### Manual Backup Before Risky Operations

```bash
# Always backup before major changes
terraform state pull > backup_$(date +%Y%m%d_%H%M%S).tfstate

# Store in a safe location
aws s3 cp backup_*.tfstate s3://st-cis-uat-tfstate-485950501937/backups/
```

---

## 7. State File Security

```
✅ Encrypted at rest (AES256)
✅ Private S3 bucket (public access blocked)
✅ S3 versioning enabled (accidental delete protection)
✅ IAM-controlled access (only authorized roles)
❌ NOT committed to Git (.gitignore excludes *.tfstate)
```

**Never commit state files to Git:**
```bash
# Verify .gitignore excludes state files
cat .gitignore | grep tfstate
# Should show: *.tfstate and *.tfstate.*
```

---

## 8. Migrating State

If you need to move state from local to remote:

```bash
# 1. Ensure backend.tf is configured
# 2. Run init with migration flag
terraform init -migrate-state

# Terraform will ask:
# "Do you want to copy existing state to the new backend?"
# Answer: yes
```
