---
name: Bug Report
about: Report a Terraform or infrastructure issue
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description

A clear description of what the bug is.

## 📋 Steps to Reproduce

```bash
# Paste exact commands run
terraform apply -target=module.core_eks
```

## ❌ Expected Behavior

What you expected to happen.

## ✅ Actual Behavior

What actually happened.

## 📄 Error Output

```
Paste full error message here
```

## 🌍 Environment

| Item | Version |
|------|---------|
| Terraform | `terraform version` output |
| AWS Provider | |
| AWS CLI | `aws --version` output |
| OS | |
| AWS Region | |

## 📁 Relevant CSV Configuration

```csv
# Paste relevant CSV rows (remove any sensitive data)
```

## 📝 Additional Context

Any other context about the problem.
```

---

## `.github/ISSUE_TEMPLATE/feature_request.md`

```markdown
---
name: Feature Request
about: Suggest an enhancement to the platform
title: '[FEAT] '
labels: enhancement
assignees: ''
---

## 🚀 Feature Description

A clear description of the feature or enhancement.

## 💡 Motivation

Why is this feature needed? What problem does it solve?

## 📐 Proposed Implementation

How would this be implemented in Terraform/CSV?

```hcl
# Example HCL or CSV snippet
```

## 🔄 Alternatives Considered

What alternatives have you considered?

## 📊 Impact

| Area | Impact |
|------|--------|
| Cost | e.g., +$10/month |
| Security | e.g., Improves network isolation |
| Complexity | e.g., Low — adds one CSV column |
| Breaking change | Yes/No |
```

---

## `.github/pull_request_template.md`

```markdown
## 📋 Pull Request Description

### What does this PR do?

<!-- Brief description of changes -->

### Why is this change needed?

<!-- Motivation and context -->

### Related Issues

Closes #<!-- issue number -->

---

## ✅ Pre-submission Checklist

### Code Quality
- [ ] `terraform fmt -recursive` passes
- [ ] `terraform validate` passes
- [ ] No hardcoded secrets, credentials, or account IDs

### Security
- [ ] `trivy fs --scanners misconfig --severity HIGH,CRITICAL .` passes
- [ ] No new 0.0.0.0/0 ingress rules without justification
- [ ] Sensitive outputs marked `sensitive = true`

### Testing
- [ ] `terraform plan` reviewed — no unexpected destroy operations
- [ ] CSV changes validated (IDs match across files)

### Documentation
- [ ] README updated if significant feature added
- [ ] `docs/` updated if modules or variables changed
- [ ] CHANGELOG.md updated
- [ ] ADR added for significant architectural decisions

---

## 🏗️ Infrastructure Changes

### Resources Added
<!-- List new resources being created -->

### Resources Modified
<!-- List existing resources being changed -->

### Resources Destroyed
<!-- List any resources being destroyed (explain why) -->

---

## 📸 Evidence

```bash
# Paste terraform plan summary:
Plan: X to add, Y to change, Z to destroy.
```

## 💰 Cost Impact

| Change | Est. Monthly Impact |
|--------|-------------------|
| <!-- resource --> | <!-- +/- $X --> |
