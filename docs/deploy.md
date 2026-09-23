# Deployment guide

## Prerequisites

- An Entra ID tenant and at least one subscription that will act as the
  **platform** subscription (hub networking, logging, budget).
- An identity with:
  - **Owner** (or Management Group Contributor + Resource Policy Contributor +
    User Access Administrator) on the parent management group - usually the
    Tenant Root Group. A Global Administrator can grant this via
    *Entra ID > Properties > Access management for Azure resources*.
  - **Owner** on the platform subscription.
- Azure CLI 2.60+ and either Terraform 1.6+ or the Bicep CLI 0.30+.
- Resource providers registered on the platform subscription:
  `Microsoft.Network`, `Microsoft.OperationalInsights`, `Microsoft.Security`,
  `Microsoft.Insights`, `Microsoft.Consumption`, `Microsoft.PolicyInsights`.

```bash
az login
az account set --subscription "<platform-subscription-id>"
```

## Option A - Terraform

```bash
cd terraform
cp example.tfvars terraform.tfvars     # terraform.tfvars is git-ignored
# edit prefix, organization_name, tags, emails, spokes, subscription_placements

export ARM_SUBSCRIPTION_ID="<platform-subscription-id>"
terraform init
terraform plan  -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

For team use, enable the `azurerm` backend block in `versions.tf` so state is
stored in a storage account instead of on your laptop.

## Option B - Bicep

Edit `bicep/main.bicepparam` (prefix, organisation name, subscription ID,
tags, emails, spokes), then deploy at the parent management group. For the
Tenant Root Group, the management group ID equals your tenant ID.

```bash
az deployment mg what-if \
  --management-group-id "<parent-management-group-id>" \
  --location westeurope \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam

az deployment mg create \
  --name alz-starter \
  --management-group-id "<parent-management-group-id>" \
  --location westeurope \
  --template-file bicep/main.bicep \
  --parameters bicep/main.bicepparam
```

`budgetStartDate` defaults to the first day of the current month. Pin it in
the parameter file (e.g. `param budgetStartDate = '2026-10-01'`) before
re-deploying in a later month, because a budget's start date cannot be moved.

## Recommended rollout

1. Deploy with policy enforcement **off** (`policy_enforcement = false` /
   `policyEnforcement = false`), which is the default in the examples.
2. Review *Azure Policy > Compliance* for the new assignments after the first
   evaluation cycle (up to 24 hours, or run
   `az policy state trigger-scan`).
3. Tag existing resource groups with every required tag, then remediate the
   `inh-tag-*` assignments to copy tags down to resources.
4. Switch enforcement **on** and re-deploy.
5. Enable the firewall (`enable_firewall = true` / `enableFirewall = true`)
   only after adding firewall policy rules for the egress your workloads
   need - all spoke traffic is forced through it.

## Cost notes

| Component | Default | Approximate cost driver |
|---|---|---|
| Management groups, policy, budgets | on | free |
| Log Analytics | on | per GB ingested beyond the free allowance; cap with `log_daily_quota_gb` |
| Defender for Cloud | Free tier | Standard plans are billed per resource |
| VNets, peering, NSGs | on | peering is billed per GB transferred |
| Azure Firewall | **off** | hourly deployment charge plus per GB processed |

## Removing the landing zone

`terraform destroy` or delete the resource groups and assignments manually.
Move subscriptions back to the parent management group before deleting the
management groups created by the starter.
