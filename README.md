# NSSDeployment — Azure Bicep Infrastructure

Bicep infrastructure-as-code for deploying Zscaler NSS (Network Security Server) virtual machines to Azure. Covers networking, security, storage, and compute across three environments (dev, staging, prod).

---

## Architecture

```
main.bicep
├── modules/security/     Key Vault + SSH public key secret
├── modules/networking/   NSG + VNet (subnets) + NAT Gateway
├── modules/storage/      Storage account + VHD blob container
└── modules/compute/      VM from custom VHD + managed disk + NIC
```

**Deploy order:** `security` → `networking` → `storage` → `compute` → KV role assignment

The VM's system-assigned managed identity is granted the **Key Vault Secrets User** role so it can retrieve the SSH public key at runtime without stored credentials.

---

## Prerequisites

- Azure CLI with Bicep: `az bicep install`
- PowerShell 7+ (for local deploy script)
- An active Azure login: `az login`
- Three pre-created resource groups (see [CI/CD Setup](#cicd-setup) below)

---

## Quick Start

```bash
# Lint
az bicep build --file main.bicep

# Validate (preflight — no changes made)
az deployment group validate \
  --resource-group rg-NSSDeployment-dev \
  --template-file main.bicep \
  --parameters environments/dev/main.bicepparam

# Preview changes
./scripts/Deploy-BicepStack.ps1 -Environment dev -WhatIf

# Deploy
./scripts/Deploy-BicepStack.ps1 -Environment dev
```

---

## Environments

| Environment | Resource Group | VNet CIDR | VM Size |
|-------------|---------------|-----------|---------|
| dev | `rg-NSSDeployment-dev` | `10.0.0.0/16` | Standard_D2s_v3 |
| staging | `rg-NSSDeployment-staging` | `10.1.0.0/16` | Standard_D2s_v3 |
| prod | `rg-NSSDeployment-prod` | `10.2.0.0/16` | Standard_D4s_v3 |

All environments deploy to **uksouth**. Each environment has two subnets (`subnet1`, `subnet2`).

---

## Parameters requiring real values before deploying

Edit `environments/{env}/main.bicepparam` and replace the following placeholders:

| Parameter | Where to find it |
|-----------|-----------------|
| `sshPublicKey` | Contents of `~/.ssh/id_rsa.pub` — or use `getSecret()` once Key Vault exists |
| `destinationAddressPrefixes` | Zscaler hub IP ranges from your Zscaler admin portal |
| `publicIpAddress` | Public IP of the machine or runner performing the deployment |
| `subnetId` | Full resource ID of `subnet1` in the environment's VNet (populated after first networking deploy) |

---

## Repository Structure

```
NSSDeployment/
├── main.bicep                        Root template (resourceGroup scope)
├── bicepconfig.json                  Linter rules (several rules set to error)
├── modules/
│   ├── networking/
│   │   ├── main.bicep               NSG + VNet + NAT Gateway orchestration
│   │   ├── nsg.bicep                Network Security Group + rules
│   │   ├── vnet.bicep               Virtual Network + subnets
│   │   └── natgw.bicep              NAT Gateway + public IP
│   ├── security/
│   │   ├── main.bicep               Key Vault orchestration
│   │   └── keyvault.bicep           Key Vault + SSH secret
│   ├── storage/
│   │   ├── main.bicep               Storage account orchestration
│   │   └── storage.bicep            Storage account + blob container
│   └── compute/
│       ├── main.bicep               VM orchestration
│       └── nssserver.bicep          VM + managed disk + NIC
├── environments/
│   ├── dev/main.bicepparam
│   ├── staging/main.bicepparam
│   └── prod/main.bicepparam
├── scripts/
│   └── Deploy-BicepStack.ps1        Local deploy / what-if script
├── docs/
│   ├── architecture.md
│   └── layout.md
└── .github/workflows/
    ├── bicep-validate.yml            PR: lint + validate + what-if
    └── bicep-deploy.yml              Push/dispatch: deploy
```

---

## CI/CD Setup

### 1. Create resource groups

```bash
az group create --name rg-NSSDeployment-dev     --location uksouth
az group create --name rg-NSSDeployment-staging --location uksouth
az group create --name rg-NSSDeployment-prod    --location uksouth
```

### 2. Configure OIDC federated identity

Create an app registration in Entra ID and add federated credentials scoped to:
- Branch `main` (for push deployments)
- Pull requests (for the validate workflow)

### 3. Add GitHub repository secrets

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### 4. Configure GitHub environments

Create three environments in **Settings → Environments**: `dev`, `staging`, `prod`.
Add a **required reviewer** protection rule to `prod` to enforce manual approval before production deploys.

---

## CI/CD Workflows

| Trigger | Workflow | Action |
|---------|----------|--------|
| PR to `main` / `develop` | `bicep-validate.yml` | Lint + ARM validate + what-if (matrix: all 3 envs in parallel) |
| Push to `main` | `bicep-deploy.yml` | Sequential: dev → staging → prod |
| `workflow_dispatch` | `bicep-deploy.yml` | Deploy to a single chosen environment |

---

## Naming Convention

```
<type>-<projectName>-<environment>[-<instance>]
```

All segments lowercase. `projectName` = `nssdeployment`.

| Resource | Dev name |
|----------|----------|
| Key Vault | `kv-nssdeployment-dev` |
| VNet | `vnet-nssdeployment-dev` |
| NSG | `nsg-nssdeployment-dev` |
| NAT Gateway | `natgw-nssdeployment-dev` |
| Storage account | `stnssdeploymentdev` |
| VM | `vm-nssdeployment-dev` |
| Managed disk | `disk-nssdeployment-dev` |
| NIC | `nic-nssdeployment-dev` |

---

## References

- [Architecture](docs/architecture.md)
- [Repository layout](docs/layout.md)
- [Bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Zscaler NSS deployment guide](https://help.zscaler.com/zia/nss-deployment-guide)
- [GitHub OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
