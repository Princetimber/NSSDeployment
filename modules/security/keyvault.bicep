@description('Required: resource location.')
param location string = resourceGroup().location

@description('Required: environment name (dev | staging | prod).')
param environmentName string

@description('Required: project name used as the resource naming infix.')
param projectName string

@description('Optional: Key Vault name. Defaults to kv-<projectName>-<environmentName>.')
param keyVaultName string = 'kv-${toLower(projectName)}-${toLower(environmentName)}'

@description('Optional: Azure AD tenant ID. Defaults to the current subscription tenant.')
param tenantId string = subscription().tenantId

@description('Optional: SKU name.')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Required: SSH public key to store as a Key Vault secret.')
@secure()
param sshPublicKey string

@description('Optional: secret name for the SSH public key.')
param sshPublicKeySecretName string = 'ssh-public-key'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Optional: tags.')
param tags object = {
  environment: environmentName
  DisplayName: 'Key Vault'
  Owner: ownerName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    // Azure RBAC is used for access control — no legacy access policies
    enableRbacAuthorization: true
    // Required for ARM deployments to retrieve secrets via getSecret()
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
  }
}

// Store the SSH public key so the VM's managed identity can retrieve it at runtime
resource sshKeySecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: sshPublicKeySecretName
  properties: {
    value: sshPublicKey
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output sshPublicKeySecretName string = sshPublicKeySecretName
