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

@description('Whether to create a new storage account or reference an existing one.')
@allowed(['new', 'existing'])
param storageNewOrExisting string = 'new'

resource storageAccountNew 'Microsoft.Storage/storageAccounts@2025-08-01' = if (storageNewOrExisting == 'new') {
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

// Always declared so the resource ID is resolvable regardless of storageNewOrExisting value.
// When storageNewOrExisting == 'new', this reference resolves the account created above.
resource storageAccountRef 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}

output storageAccountId string = storageAccountRef.id
output storageAccountName string = storageAccountRef.name
