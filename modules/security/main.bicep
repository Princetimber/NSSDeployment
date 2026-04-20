// Module : security
// Purpose: Key Vault, RBAC assignments, and policy resources

targetScope = 'resourceGroup'

@description('Azure region.')
param location string = resourceGroup().location

@description('Environment name: dev | staging | prod.')
param environmentName string = 'dev'

@description('Project name used as a resource naming prefix.')
param projectName string

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Resource tags.')
param tags object = {
  environment: environmentName
  DisplayName: projectName
  Owner: ownerName
}

@description('Required: SSH public key for NSS server access. Stored as a Key Vault secret.')
@secure()
param sshPublicKey string

@description('Optional: secret name for the SSH public key in Key Vault.')
param sshPublicKeySecretName string = 'ssh-public-key'

module keyVault 'keyvault.bicep' = {
  name: '${projectName}-keyvault'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    ownerName: ownerName
    tags: tags
    sshPublicKey: sshPublicKey
    sshPublicKeySecretName: sshPublicKeySecretName
  }
}

output keyVaultId string = keyVault.outputs.keyVaultId
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output sshPublicKeySecretName string = keyVault.outputs.sshPublicKeySecretName
