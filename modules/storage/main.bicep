// Module : storage
// Purpose: Storage accounts and related data resources

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

@description('Required: storage account name (3–24 lowercase alphanumeric).')
param storageAccountName string

@description('Required: name of the virtual network allowed to access the storage account.')
param vnetName string

@description('Required: subnet names allowed to access the storage account.')
@allowed([
  'subnet1'
  'subnet2'
])
param subnets array

@description('Required: public IP address allowed to access the storage account.')
param publicIpAddress string

@description('Optional: blob container name for VHD uploads.')
param vhdContainerName string = 'vhds'

module storageAccount './storage.bicep' = {
  name: '${projectName}-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    environmentName: environmentName
    tags: tags
    ownerName: ownerName
    vnetName: vnetName
    subnets: subnets
    publicIpAddress: publicIpAddress
    vhdContainerName: vhdContainerName
  }
}

output storageAccountId string = storageAccount.outputs.storageAccountId
output storageAccountName string = storageAccount.outputs.storageAccountNameOutput
output vhdContainerName string = storageAccount.outputs.vhdContainerName
output vhdContainerUri string = storageAccount.outputs.vhdContainerUri
