# Module: storage

Deploys a storage account with a VHD blob container used to host the NSS server disk image before VM provisioning. Access is locked down to specific VNet subnets (via service endpoints) and an explicit public IP allowlist.

**Depends on:** networking module (VNet and subnets must exist before service endpoint rules can reference them).

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.Storage/storageAccounts` | Supplied via `storageAccountName` parameter |
| `Microsoft.Storage/storageAccounts/blobServices` | `default` |
| `Microsoft.Storage/storageAccounts/blobServices/containers` | `vhds` (configurable) |

**Storage account settings:** Standard_LRS, StorageV2, Hot tier, HTTPS-only, immutable blob storage (30-day unlocked policy), VNet firewall with `Deny` default action.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | string | No | `resourceGroup().location` | Azure region |
| `environmentName` | string | No | `'dev'` | Environment identifier |
| `projectName` | string | **Yes** | — | Naming prefix (for tags) |
| `ownerName` | string | No | `''` | Owner tag value |
| `tags` | object | No | derived | Resource tags |
| `storageAccountName` | string | **Yes** | — | Storage account name (3–24 lowercase alphanumeric, no hyphens) |
| `vnetName` | string | **Yes** | — | Name of the VNet whose subnets get service endpoint access |
| `subnets` | array | **Yes** | — | Subnet names (strings) to allow via VNet rules. Allowed values: `'subnet1'`, `'subnet2'` |
| `publicIpAddress` | string | **Yes** | — | Public IP address allowed through the storage firewall (deployer or jump-host IP) |
| `vhdContainerName` | string | No | `'vhds'` | Blob container name for VHD uploads |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `storageAccountId` | string | Resource ID of the storage account |
| `storageAccountName` | string | Name of the storage account |
| `vhdContainerName` | string | Name of the VHD blob container |
| `vhdContainerUri` | string | Full URI of the VHD container (used by compute module to build the VHD blob URI) |

---

## Usage

```bicep
module storage './modules/storage/main.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    storageAccountName: 'stnssdeploymentdev'
    vnetName: 'vnet-nssdeployment-dev'
    subnets: ['subnet1', 'subnet2']
    publicIpAddress: publicIpAddress
    vhdContainerName: 'vhds'
  }
  dependsOn: [networking]   // VNet must exist before service endpoint rules resolve
}
```

> **Before deploying compute:** upload your VHD to the container using the `vhdContainerUri` output:
>
> ```bash
> az storage blob upload \
>   --account-name stnssdeploymentdev \
>   --container-name vhds \
>   --name nssserver.vhd \
>   --file /path/to/nssserver.vhd \
>   --auth-mode login
> ```
