# Module: compute

Deploys the NSS virtual machine by importing a VHD from Azure Blob Storage as a managed disk, attaching a network interface connected to the VNet subnet, and creating the VM with a system-assigned managed identity.

**Depends on:** networking module (the subnet referenced by `subnetId` must exist) and storage module (VHD container URI is passed in).

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.Compute/disks` | `disk-{projectName}-{env}` |
| `Microsoft.Network/networkInterfaces` | `nic-{projectName}-{env}` |
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
| `vhdBlobUri` | string | **Yes** | — | Full URI of the VHD blob (e.g. `https://<account>.blob.core.windows.net/vhds/nssserver.vhd`) |
| `storageAccountId` | string | **Yes** | — | Resource ID of the storage account holding the VHD |
| `subnetId` | string | **Yes** | — | Resource ID of the subnet for the VM NIC |
| `vmSize` | string | No | `'Standard_D2s_v3'` | VM size. Allowed: `Standard_DS1_v2`, `Standard_DS2_v2`, `Standard_DS3_v2`, `Standard_DS4_v2`, `Standard_DS5_v2`, `Standard_D2s_v3`, `Standard_D4s_v3` |
| `osType` | string | No | `'Linux'` | OS type of the VHD image. Allowed: `'Linux'` |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vmId` | string | Resource ID of the virtual machine |
| `vmName` | string | Name of the virtual machine |
| `nicPrivateIpAddress` | string | Private IP address assigned to the NIC |
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
    vhdBlobUri: '${storage.outputs.vhdContainerUri}/nssserver.vhd'
    storageAccountId: storage.outputs.storageAccountId
    subnetId: '/subscriptions/<id>/resourceGroups/rg-NSSDeployment-dev/providers/Microsoft.Network/virtualNetworks/vnet-nssdeployment-dev/subnets/subnet1'
    vmSize: 'Standard_D2s_v3'
    osType: 'Linux'
  }
  dependsOn: [networking]   // subnet must exist before NIC is created
}
```

> **Important:** The VHD blob must be uploaded to the storage container **before** running this module. The managed disk creation (`createOption: Import`) will fail if the blob does not exist at `vhdBlobUri`.
