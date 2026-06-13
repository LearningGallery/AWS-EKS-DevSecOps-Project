# 📚 Documentation Index

**AWS EKS DevSecOps Platform — Complete Documentation**

---

## 🗂️ All Documents

| # | Document | Description | Audience |
|---|----------|-------------|----------|
| — | [README.md](../README.md) | Project overview and quick start | All |
| 00 | [OBJECTIVES](00-OBJECTIVES.md) | Goals, scope, success criteria | All |
| 01 | [PROJECT-OVERVIEW](01-PROJECT-OVERVIEW.md) | Business context, problem, solution | All |
| 02 | [ARCHITECTURE](02-ARCHITECTURE.md) | Infrastructure design, topology, diagrams | Architects, Senior Engineers |
| 03 | [MODULES-OVERVIEW](03-MODULES-OVERVIEW.md) | Module strategy and dependency graph | Engineers |
| 04 | [MODULE-REFERENCE](04-MODULE-REFERENCE.md) | Per-module deep-dive documentation | Engineers |
| 05 | [VARIABLES-GUIDE](05-VARIABLES-GUIDE.md) | All input variables and CSV fields | Engineers |
| 06 | [OUTPUTS-GUIDE](06-OUTPUTS-GUIDE.md) | All output values and usage | Engineers |
| 07 | [QUICK-START](07-QUICK-START.md) | Step-by-step deployment tutorial | Beginners |
| 08 | [DEPLOYMENT-GUIDE](08-DEPLOYMENT-GUIDE.md) | Detailed deployment procedures | Engineers |
| 09 | [STATE-MANAGEMENT](09-STATE-MANAGEMENT.md) | Terraform state guide | Engineers |
| 10 | [TROUBLESHOOTING](10-TROUBLESHOOTING.md) | Common errors and solutions | All |
| 11 | [SECURITY-GUIDE](11-SECURITY-GUIDE.md) | Security architecture and best practices | Security, Architects |
| 12 | [COST-OPTIMIZATION](12-COST-OPTIMIZATION.md) | Cost management and estimation | Managers, Engineers |
| 13 | [BEST-PRACTICES](13-BEST-PRACTICES.md) | Terraform and IaC best practices | Engineers |
| 14 | [RUNBOOK](14-RUNBOOK.md) | Day-2 operational procedures | Operations |
| 15 | [KNOWN-ISSUES](15-KNOWN-ISSUES.md) | Limitations and workarounds | All |
| 16 | [ROADMAP](16-ROADMAP.md) | Future enhancements and plans | All |

---

## 🏗️ Architecture Decision Records (ADRs)

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](adr/ADR-001-TERRAFORM-VERSION.md) | Terraform Version Selection | Accepted |
| [ADR-002](adr/ADR-002-MODULE-STRATEGY.md) | Module Architecture Strategy | Accepted |
| [ADR-003](adr/ADR-003-STATE-BACKEND.md) | Remote State Backend | Accepted |
| [ADR-004](adr/ADR-004-CLOUD-PROVIDER-CHOICE.md) | Cloud Provider Choice | Accepted |
| [ADR-005](adr/ADR-005-CSV-DATA-ENGINE.md) | CSV-Driven Data Engine | Accepted |
| [ADR-006](adr/ADR-006-DEVSECOPS-PIPELINE.md) | DevSecOps Pipeline Design | Accepted |

---

## 📊 Diagrams

| Diagram | Description |
|---------|-------------|
| [01-infrastructure-topology](diagrams/01-infrastructure-topology.md) | Full AWS infrastructure topology |
| [02-module-dependency-graph](diagrams/02-module-dependency-graph.md) | Terraform module relationships |
| [03-resource-deployment-flow](diagrams/03-resource-deployment-flow.md) | Deployment sequence flow |
| [04-data-flow](diagrams/04-data-flow.md) | Application and CI/CD data flow |

---

## 💡 Examples

| Example | Description |
|---------|-------------|
| [basic-deployment](examples/basic-deployment.md) | Minimal configuration deployment |
| [advanced-deployment](examples/advanced-deployment.md) | Full-featured deployment example |
| [multi-environment](examples/multi-environment.md) | Multi-environment pattern |
| [example-tfvars](examples/example-tfvars.md) | Example variable files |

---

## 🚀 Getting Started Fast

```
New to the project?    → Start with 07-QUICK-START.md
Want the full picture? → Read 02-ARCHITECTURE.md
Having issues?         → Check 10-TROUBLESHOOTING.md
Understanding modules? → Read 04-MODULE-REFERENCE.md
Security questions?    → Read 11-SECURITY-GUIDE.md
```