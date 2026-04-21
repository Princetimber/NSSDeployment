# Module: compute

Deploys the NSS virtual machine by importing a VHD from Azure Blob Storage as a managed disk, attaching two network interfaces, and creating the VM with a system-assigned managed identity.

**Depends on:** networking module (VNet, subnets, and NSG are resolved via `existing` declarations using the naming convention) and the storage module output (`storageAccountName`).

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.Compute/disks` | `disk-{projectName}-{env}` |
| `Microsoft.Network/networkInterfaces` | `nic1-{projectName}-{env}` (primary, subnet1, dynamic IP) |
| `Microsoft.Network/networkInterfaces` | `nic2-{projectName}-{env}` (secondary, subnet2, static IP) |
| `Microsoft.Compute/virtualMachines` | `vm-{projectName}-{env}` |

**Disk:** Premium_LRS, 512 GB, imported from VHD blob (`createOption: Import`), HyperV Gen1.  
**VM identity:** SystemAssigned — principal ID is output so `main.bicep` can assign the Key Vault Secrets User role.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | string | No | `resourceGroup().location` | Azure region |
| `environmentName` | string | No | `'dev'` | Environment identifier |
| `projectName` | string | **Yes** | — | Naming prefix |
| `ownerName` | string | No | `''` | Owner tag value |
| `tags` | object | No | derived | Resource tags |
| `storageAccountName` | string | **Yes** | — | Name of the storage account holding the VHD blob. The VHD URI is built internally: `https://{storageAccountName}.blob.{environment().suffixes.storage}/nss/znss_5_2_osdisk.vhd` |
| `storageAccountId` | string | **Yes** | — | Resource ID of the storage account (provides authorization context for disk import) |
| `nic2PrivateIpAddress` | string | **Yes** | — | Static private IP address for the secondary NIC in subnet2 |
| `vmSize` | string | No | `'Standard_D2s_v3'` | VM size. Allowed: `Standard_DS1_v2`, `Standard_DS2_v2`, `Standard_DS3_v2`, `Standard_DS4_v2`, `Standard_DS5_v2`, `Standard_D2s_v3`, `Standard_D4s_v3` |
| `osType` | string | No | `'Linux'` | OS type of the VHD image. Allowed: `'Linux'` |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vmId` | string | Resource ID of the virtual machine |
| `vmName` | string | Name of the virtual machine |
| `nicPrivateIpAddress` | string | Private IP address assigned to the primary NIC |
| `vmPrincipalId` | string | Object ID of the VM's system-assigned managed identity (used to assign KV role) |

---

## Usage

```bicep
module compute './modules/compute/main.bicep' = {
  name: 'computeDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    storageAccountName: storage.outputs.storageAccountName
    storageAccountId: storage.outputs.storageAccountId
    nic2PrivateIpAddress: nic2PrivateIpAddress
    vmSize: 'Standard_D2s_v3'
  }
  dependsOn: [networking]   // VNet, subnets, and NSG must exist before NICs are created
}
```

> **Important:** The VHD blob must be uploaded to the storage account **before** running this module. The managed disk creation (`createOption: Import`) will fail if the blob does not exist at `nss/znss_5_2_osdisk.vhd` in the specified storage account.
