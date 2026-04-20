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

// ── Compute ───────────────────────────────────────────────────────────────────

@description('Required: file name of the VHD blob inside the container (e.g. nssserver.vhd).')
param vhdFileName string

@description('Required: resource ID of the subnet for the VM network interface. Must reference a subnet created by the networking module.')
param subnetId string

@description('Optional: VM size.')
@allowed([
  'Standard_DS1_v2'
  'Standard_DS2_v2'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
param vmSize string = 'Standard_D2s_v3'

@description('Optional: OS type of the VHD image.')
param osType string = 'Linux'

module compute './modules/compute/main.bicep' = {
  name: 'computeDeploy'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
    vhdBlobUri: '${storage.outputs.vhdContainerUri}/${vhdFileName}'
    storageAccountId: storage.outputs.storageAccountId
    subnetId: subnetId
    vmSize: vmSize
    osType: osType
  }
  // Subnet referenced by subnetId must exist before NIC is created
  dependsOn: [networking]
}

// ── Key Vault role assignment ─────────────────────────────────────────────────
// Grant the VM's system-assigned managed identity the Key Vault Secrets User role
// so it can retrieve the SSH public key (and any future secrets) at runtime.

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

// Derive names from params (same formulae used in child modules) so the existing-resource
// reference and the role-assignment name/scope are known at deploy start (BCP120).
var kvName = 'kv-${toLower(projectName)}-${toLower(environmentName)}'
var vmName = 'vm-${toLower(projectName)}-${toLower(environmentName)}'

resource kv 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: kvName
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceId('Microsoft.KeyVault/vaults', kvName), resourceId('Microsoft.Compute/virtualMachines', vmName), keyVaultSecretsUserRoleId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: compute.outputs.vmPrincipalId
    principalType: 'ServicePrincipal'
  }
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

@description('Virtual machine resource ID.')
output vmId string = compute.outputs.vmId

@description('VM private IP address.')
output nicPrivateIpAddress string = compute.outputs.nicPrivateIpAddress
