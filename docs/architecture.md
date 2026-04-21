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
│       ├── Microsoft.Network/networkInterfaces        nic1-nssdeployment-{env}  (primary, subnet1, dynamic IP)
│       ├── Microsoft.Network/networkInterfaces        nic2-nssdeployment-{env}  (secondary, subnet2, static .5)
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
| Secrets | SSH public key injected at deploy time via `SSH_PUBLIC_KEY` GitHub Actions environment secret; stored in Key Vault — never hardcoded in param files or outputs |
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

The NSG enforces five rules:
- **Inbound:** Allow SSH (22) from any source to subnet1 (`10.2.x.1.0/24`)
- **Outbound:** Allow HTTPS (443) to Zscaler hub IP ranges (from `destinationAddressPrefixes` param)
- **Outbound:** Allow HTTPS (443) to Zscaler Remote Support IP `199.168.148.101`
- **Outbound:** Allow DNS (UDP 53) to any destination
- **Outbound:** Allow NTP (UDP 123) to any destination

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
| `SSH_PUBLIC_KEY` | Per-environment SSH public key for NSS VM access. Set in GitHub Environments (`dev`, `staging`, `prod`), not as a repo-level secret. |

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
| Network Interface (primary) | `nic1` | `nic1-nssdeployment-dev` (subnet1, dynamic IP) |
| Network Interface (secondary) | `nic2` | `nic2-nssdeployment-dev` (subnet2, static IP `.5`) |

¹ Storage account names may not contain hyphens.

---

## Deployment Lifecycle

### Pre-deploy (each environment)

Each deploy job runs these steps before `az deployment group create`:

1. Deallocate VM if running — ARM cannot update NIC count on a running VM.
2. Delete stale `nic-nssdeployment-{env}` NIC if it exists (pre-rename cleanup).
3. Delete any NSGs not matching `nsg-nssdeployment-{env}` (duplicate cleanup).
4. Delete stale Key Vault Secrets User role assignments on the KV — avoids `RoleAssignmentUpdateNotPermitted` when the VM is recreated and gets a new managed identity principal ID.

The KV role assignment name is deterministic: `guid(kv.id, roleId, vm-resource-id)`. Deleting stale assignments before deploy ensures a clean re-creation.

### VHD source

The OS disk is provisioned from a pre-uploaded VHD in each environment's storage account. The blob URI is built internally by the compute module:

```
https://<storageAccountName>.blob.<environment().suffixes.storage>/nss/znss_5_2_osdisk.vhd
```

No SAS token is required — access is granted via VNet service endpoints.

### Post-prod cleanup (push-triggered only)

After a successful prod deploy, dev and staging resources are deleted in dependency order to avoid leaving unused infrastructure running:

VM → disk → NICs → NAT Gateway (subnets detached first) → VNet → NSGs → Public IPs → Key Vault (delete + purge)

Storage accounts are intentionally preserved.

---

## References

- [Bicep documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure resource naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [GitHub OIDC with Azure](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
- [Zscaler NSS deployment guide](https://help.zscaler.com/zia/nss-deployment-guide)
