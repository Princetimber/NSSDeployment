# Architecture Overview

## Scope

All resources target the **Resource Group** scope (`targetScope = 'resourceGroup'`). The three resource groups — `rg-NSSDeployment-dev`, `rg-NSSDeployment-staging`, `rg-NSSDeployment-prod` — must be pre-created before any deployment runs.

---

## Resource Map

```
main.bicep (resourceGroup scope)
│
├── module: security  →  modules/security/main.bicep
│   └── keyvault.bicep
│       ├── Microsoft.KeyVault/vaults          kv-nssdeployment-{env}
│       └── Microsoft.KeyVault/vaults/secrets  ssh-public-key
│
├── module: networking  →  modules/networking/main.bicep
│   ├── nsg.bicep
│   │   └── Microsoft.Network/networkSecurityGroups   nsg-nssdeployment-{env}
│   ├── vnet.bicep  (dependsOn: nsg)
│   │   └── Microsoft.Network/virtualNetworks         vnet-nssdeployment-{env}
│   │       ├── subnet1  (NSS server subnet)
│   │       └── subnet2  (management subnet)
│   └── natgw.bicep  (dependsOn: vnet)
│       ├── Microsoft.Network/publicIPAddresses        natgw-nssdeployment-{env}pubIp
│       ├── Microsoft.Network/natGateways              natgw-nssdeployment-{env}
│       └── Microsoft.Network/virtualNetworks/subnets  (associates NAT GW → subnet1)
│
├── module: storage  (dependsOn: networking)  →  modules/storage/main.bicep
│   └── storage.bicep
│       ├── Microsoft.Storage/storageAccounts          stnssdeployment{env}
│       ├── Microsoft.Storage/.../blobServices         default
│       └── Microsoft.Storage/.../containers           vhds
│
├── module: compute  (dependsOn: networking)  →  modules/compute/main.bicep
│   └── nssserver.bicep
│       ├── Microsoft.Compute/disks                    disk-nssdeployment-{env}
│       ├── Microsoft.Network/networkInterfaces        nic-nssdeployment-{env}
│       └── Microsoft.Compute/virtualMachines          vm-nssdeployment-{env}
│           └── identity: SystemAssigned
│
└── resource: kvRoleAssignment  (dependsOn: compute)
    └── Microsoft.Authorization/roleAssignments
        └── Key Vault Secrets User → VM managed identity
```

---

## Deploy Order

```
security ──────────────────────────────────────────┐
networking ─────────────────────────────────────────┤
                                                    ▼
                               storage (needs networking VNet)
                               compute (needs networking subnet)
                                                    │
                                                    ▼
                                         kvRoleAssignment
                                     (VM → KV Secrets User)
```

Security and networking deploy in parallel (no dependency between them). Storage and compute both declare `dependsOn: [networking]` because they reference the VNet/subnets as existing resources.

---

## Security Design

| Control | Implementation |
|---------|---------------|
| Secrets | SSH public key stored in Key Vault — never in param files or outputs |
| VM access | System-assigned managed identity with least-privilege KV Secrets User role |
| Storage access | VNet service endpoints + IP allowlist (no public blob access) |
| CI/CD credentials | OIDC Workload Identity Federation — no long-lived secrets in GitHub |
| Linter | `bicepconfig.json` enforces `outputs-should-not-contain-secrets`, `no-hardcoded-location`, `secure-secrets-in-params` as errors |

---

## Networking Design

Each environment has an isolated VNet with non-overlapping address spaces:

| Environment | VNet CIDR | subnet1 (NSS) | subnet2 (Mgmt) |
|-------------|-----------|---------------|----------------|
| dev | `10.0.0.0/16` | `10.0.1.0/24` | `10.0.2.0/24` |
| staging | `10.1.0.0/16` | `10.1.1.0/24` | `10.1.2.0/24` |
| prod | `10.2.0.0/16` | `10.2.1.0/24` | `10.2.2.0/24` |

The NSG enforces:
- **Inbound:** Allow HTTPS (443), HTTP (80), SSH (22)
- **Outbound:** Allow Zscaler hub IP ranges on ports 443 and 12002; DNS on UDP 53

The NAT Gateway is associated with `subnet1` to provide deterministic outbound public IP for the NSS server.

---

## Environments

| Environment | Resource Group | Deploy trigger | Approval gate |
|-------------|---------------|----------------|---------------|
| dev | `rg-NSSDeployment-dev` | Push to `main` | None |
| staging | `rg-NSSDeployment-staging` | After dev succeeds | None |
| prod | `rg-NSSDeployment-prod` | After staging succeeds | Required reviewer |

For `workflow_dispatch`, each environment can be targeted independently (the sequential gate is bypassed).

---

## OIDC Authentication

Workflows use Workload Identity Federation — no long-lived credentials stored in GitHub.

### Required Repository Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | App registration client ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### Required GitHub Environments

Create in **Settings → Environments**: `dev`, `staging`, `prod`.
Configure a required reviewer and branch filter (`main`) on `prod`.

---

## Naming Convention

```
<type>-<projectName>-<environment>[-<instance>]
```

All segments **lowercase**. `<type>` is the abbreviated Azure resource type. Never derive resource names from the resource group name — always pass `projectName` and `environmentName` as params and apply `toLower()`.

| Resource type | Abbreviation | Example |
|---------------|-------------|---------|
| Key Vault | `kv` | `kv-nssdeployment-dev` |
| Virtual Network | `vnet` | `vnet-nssdeployment-prod` |
| Network Security Group | `nsg` | `nsg-nssdeployment-staging` |
| NAT Gateway | `natgw` | `natgw-nssdeployment-dev` |
| Storage account | `st` | `stnssdeploymentdev` ¹ |
| Virtual Machine | `vm` | `vm-nssdeployment-dev` |
| Managed Disk | `disk` | `disk-nssdeployment-dev` |
| Network Interface | `nic` | `nic-nssdeployment-dev` |

¹ Storage account names may not contain hyphens.

---

## References

- [Bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure resource naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [GitHub OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [Zscaler NSS deployment guide](https://help.zscaler.com/zia/nss-deployment-guide)
