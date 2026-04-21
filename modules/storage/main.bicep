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

@description('Required: storage account name (3–24 lowercase alphanumeric).')
param storageAccountName string

@description('Required: name of the virtual network allowed to access the storage account.')
param vnetName string

@description('Required: subnet names allowed to access the storage account.')
param subnets array

@description('Required: public IP address allowed to access the storage account.')
param publicIpAddress string

module storageAccount './storage.bicep' = {
  name: '${projectName}-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    environmentName: environmentName
    ownerName: ownerName
    vnetName: vnetName
    subnets: subnets
    publicIpAddress: publicIpAddress
  }
}

output storageAccountId string = storageAccount.outputs.storageAccountId
output storageAccountName string = storageAccount.outputs.storageAccountName
