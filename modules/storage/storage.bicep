@description('Required: storage account name (3–24 lowercase alphanumeric).')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Required: resource location. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional: storage account SKU. Defaults to Standard_LRS.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Optional: environment name (dev | staging | prod).')
param environmentName string = 'dev'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Optional: tags.')
param tags object = {
  environment: environmentName
  DisplayName: 'Storage Account'
  Owner: ownerName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
