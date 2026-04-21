# Module: storage

Deploys (or references) a storage account used to host the NSS server VHD blob before VM provisioning.

**Depends on:** nothing — storage is standalone and has no dependency on the networking module.

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.Storage/storageAccounts` | Supplied via `storageAccountName` parameter |

**Storage account settings:** Standard_LRS, StorageV2, Hot tier, HTTPS-only, TLS 1.2 minimum, public blob access disabled.

> **Container:** The VHD blob must be uploaded to a container named `nss` inside the storage account before deploying the compute module. The blob path expected is `nss/znss_5_2_osdisk.vhd`.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | string | No | `resourceGroup().location` | Azure region |
| `environmentName` | string | No | `'dev'` | Environment identifier |
| `projectName` | string | **Yes** | — | Naming prefix (for tags) |
| `ownerName` | string | No | `''` | Owner tag value |
| `storageAccountName` | string | **Yes** | — | Storage account name (3–24 lowercase alphanumeric, no hyphens) |
| `storageNewOrExisting` | string | No | `'new'` | `'new'` creates the account; `'existing'` references a pre-existing account. All three environments currently set this to `'existing'`. Allowed: `'new'`, `'existing'` |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `storageAccountId` | string | Resource ID of the storage account |
| `storageAccountName` | string | Name of the storage account |

---

## Usage

```bicep
module storage './modules/storage/main.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    storageAccountName: 'stnssdeploymentdev'
    storageNewOrExisting: 'existing'
  }
}
```

> **Before deploying compute:** upload the VHD to the `nss` container in the storage account:
>
> ```bash
> az storage blob upload \
>   --account-name stnssdeploymentdev \
>   --container-name nss \
>   --name znss_5_2_osdisk.vhd \
>   --file /path/to/znss_5_2_osdisk.vhd \
>   --auth-mode login
> ```
