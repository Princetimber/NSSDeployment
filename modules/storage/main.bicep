// Module : storage
// Purpose: Storage account

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

@description('Whether to create a new storage account or reference an existing one.')
@allowed(['new', 'existing'])
param storageNewOrExisting string = 'new'

module storageAccount './storage.bicep' = {
  name: '${projectName}-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    environmentName: environmentName
    ownerName: ownerName
    storageNewOrExisting: storageNewOrExisting
  }
}

output storageAccountId string = storageAccount.outputs.storageAccountId
output storageAccountName string = storageAccount.outputs.storageAccountName
