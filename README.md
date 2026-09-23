# Azure Landing Zone Starter

Secure, cost-tagged Azure landing zone templates (Terraform + Bicep) for small and mid-size businesses.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Status: v0.1.0](https://img.shields.io/badge/status-v0.1.0-green)
[![CI](https://github.com/calliarc/azure-landing-zone-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/calliarc/azure-landing-zone-starter/actions/workflows/ci.yml)

> **Status:** v0.1.0, the first working release. Terraform and Bicep templates are usable today; star or watch the repo to follow progress.

## Features

- Management group and subscription layout sized for SMBs (root, platform, landing zones, sandbox, decommissioned)
- Hub-and-spoke networking with an NSG per subnet and optional Azure Firewall with forced egress routing
- Baseline Azure Policy assignments using built-in definitions: required tags (with inheritance), allowed regions, secure defaults and the Microsoft cloud security benchmark
- Centralized logging with Log Analytics (Activity Log export) and Defender for Cloud plans and security contact
- Monthly budget alerts (actual and forecast) and cost-allocation tags from day one
- Equivalent Terraform (azurerm 4.x) and Bicep versions

## Tech stack

- Terraform >= 1.6 with the `hashicorp/azurerm` provider ~> 4.0
- Bicep
- Azure Policy (built-in definitions)
- GitHub Actions

## Getting started

```text
terraform/            Root module, example.tfvars and modules/
  modules/management-groups   modules/networking   modules/policy
  modules/logging             modules/budgets
bicep/                main.bicep, main.bicepparam and modules/
docs/architecture.md  Diagrams and the list of policy assignments
docs/deploy.md        Prerequisites, permissions, rollout and cost notes
```

You need Owner (or equivalent) on the parent management group, usually the Tenant Root Group, and on the platform subscription. See [docs/deploy.md](docs/deploy.md) for details.

**Terraform**

```bash
cd terraform
cp example.tfvars terraform.tfvars   # edit prefix, tags, emails, spokes
export ARM_SUBSCRIPTION_ID="<platform-subscription-id>"
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

**Bicep**

```bash
# edit bicep/main.bicepparam first
az deployment mg create \
  --management-group-id "<parent-management-group-id>" \
  --location westeurope \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

The examples assign policies in audit-only mode and leave Azure Firewall off, so a first deployment costs little and blocks nothing. Turn on enforcement and the firewall once you have reviewed compliance and added firewall rules. The architecture is described in [docs/architecture.md](docs/architecture.md).

## Roadmap

- [x] Initial release
- [x] Documentation and examples
- [x] CI (fmt, validate, Bicep build)
- [ ] Automated deployment tests
- [ ] Optional VPN gateway and Private DNS zones

Have an idea? [Open an issue](https://github.com/calliarc/azure-landing-zone-starter/issues).

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 CalliArc

---

Built and maintained by [CalliArc](https://www.calliarc.com/). Need help with Azure cloud migration? [Talk to our team](https://www.calliarc.com/services/azure-cloud-migration/).
