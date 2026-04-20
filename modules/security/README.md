# Module: security

Deploys a Key Vault with RBAC authorization enabled and stores the NSS server SSH public key as a secret. The VM's system-assigned managed identity is granted the Key Vault Secrets User role by `main.bicep` after compute deploys.

---

## Resources created

| Resource | Name pattern |
|----------|-------------|
| `Microsoft.KeyVault/vaults` | `kv-{projectName}-{env}` |
| `Microsoft.KeyVault/vaults/secrets` | `ssh-public-key` (configurable) |

**Key Vault settings:** RBAC authorization, soft-delete (90-day retention), enabled for ARM deployment and template deployment.

---

## Parameters

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `location` | string | No | `resourceGroup().location` | Azure region |
| `environmentName` | string | No | `'dev'` | Environment identifier |
| `projectName` | string | **Yes** | — | Naming prefix |
| `ownerName` | string | No | `''` | Owner tag value |
| `tags` | object | No | derived | Resource tags |
| `sshPublicKey` | string (`@secure()`) | **Yes** | — | SSH public key to store in Key Vault |
| `sshPublicKeySecretName` | string | No | `'ssh-public-key'` | Name for the secret in Key Vault |

---

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `keyVaultId` | string | Resource ID of the Key Vault |
| `keyVaultName` | string | Name of the Key Vault |
| `keyVaultUri` | string | Vault URI (e.g. `https://kv-nssdeployment-dev.vault.azure.net/`) |
| `sshPublicKeySecretName` | string | Name of the stored SSH key secret |

---

## Usage

```bicep
module security './modules/security/main.bicep' = {
  name: 'securityDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    sshPublicKey: sshPublicKey               // @secure() — never logged or output
    sshPublicKeySecretName: 'ssh-public-key'
  }
}
```

> **Note:** `sshPublicKey` is decorated `@secure()` and will never appear in deployment logs or outputs. For CI/CD pipelines, supply it via `getSecret()` once the Key Vault exists:
>
> ```bicep
> param sshPublicKey = getSecret('<subscriptionId>', 'rg-NSSDeployment-dev', 'kv-nssdeployment-dev', 'ssh-public-key')
> ```
