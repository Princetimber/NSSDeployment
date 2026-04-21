targetScope = 'resourceGroup'

@description('Short environment identifier: dev | staging | prod.')
param environmentName string

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Project name used as a resource naming prefix.')
param projectName string = 'nssdeployment'

@description('Resource tags applied to all resources.')
param tags object = {
  Environment: environmentName
  Project: projectName
  ManagedBy: 'bicep'
}

// ── Security ──────────────────────────────────────────────────────────────────

@description('Required: SSH public key for NSS server access. Stored securely in Key Vault.')
@secure()
param sshPublicKey string

@description('Optional: secret name for the SSH public key in Key Vault.')
param sshPublicKeySecretName string = 'ssh-public-key'

module security './modules/security/main.bicep' = {
  name: 'securityDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    sshPublicKey: sshPublicKey
    sshPublicKeySecretName: sshPublicKeySecretName
  }
}

// ── Networking ────────────────────────────────────────────────────────────────

@description('Required: destination address prefixes for NSG outbound rules. Use the Zscaler hub IP ranges for your region.')
param destinationAddressPrefixes array

@description('Required: source address prefixes for NSG outbound rules. Use the subnet CIDR blocks of the VNet.')
param sourceAddressPrefixes array

@description('Required: address prefixes for the virtual network (e.g. [\'10.0.0.0/16\']).')
param addressPrefixes array

@description('Required: subnets to create in the virtual network. Each entry must be an object with name and addressPrefix.')
param networkingSubnets array

@description('Required: DNS servers for the virtual network.')
param dnsServers array

@description('Required: subnets to associate with the NAT Gateway. Same object shape as networkingSubnets.')
param natGatewaySubnets array

module networking './modules/networking/main.bicep' = {
  name: 'networkingDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    destinationAddressPrefixes: destinationAddressPrefixes
    sourceAddressPrefixes: sourceAddressPrefixes
    addressPrefixes: addressPrefixes
    subnets: networkingSubnets
    dnsServers: dnsServers
    natGatewaySubnets: natGatewaySubnets
  }
}

// ── Storage ──────────────────────────────────────────────────────────────────

@description('Required: storage account name (3–24 lowercase alphanumeric).')
param storageAccountName string

@description('Required: name of the virtual network allowed to access the storage account. Must match the VNet created by the networking module.')
param vnetName string

@description('Required: subnet names (strings) allowed to access the storage account via service endpoints. Must match subnet names in networkingSubnets.')
param subnets array

@description('Required: public IP address allowed to access the storage account.')
param publicIpAddress string

@description('Optional: blob container name for VHD uploads. Defaults to vhds.')
param vhdContainerName string = 'vhds'

module storage './modules/storage/main.bicep' = {
  name: 'storageDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    storageAccountName: storageAccountName
    vnetName: vnetName
    subnets: subnets
    publicIpAddress: publicIpAddress
    vhdContainerName: vhdContainerName
  }
  // VNet and subnets must exist before storage sets up service endpoint rules
  dependsOn: [networking]
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Name of the resource group.')
output resourceGroupName string = resourceGroup().name

@description('Deployment location.')
output location string = location

@description('Key Vault resource ID.')
output keyVaultId string = security.outputs.keyVaultId

@description('Key Vault URI.')
output keyVaultUri string = security.outputs.keyVaultUri

@description('NSG resource ID.')
output nsgId string = networking.outputs.nsgId

@description('Virtual network resource ID.')
output vnetId string = networking.outputs.vnetId

@description('NAT Gateway public IP.')
output natGatewayPublicIpName string = networking.outputs.publicIpName

@description('Storage account resource ID.')
output storageAccountId string = storage.outputs.storageAccountId

@description('VHD container URI — upload your VHD here before deploying compute.')
output vhdContainerUri string = storage.outputs.vhdContainerUri

