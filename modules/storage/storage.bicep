@description('Required: storage account name.')
@minLength(3)
@maxLength(24)
param storageAccountName string = '${uniqueString(resourceGroup().id)}stga'

@description('Required: resource location. It defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional: storage account SKU. It defaults to Standard_LRS.')
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

@description('Required: storage account kind. It defaults to StorageV2.')
@allowed([
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Optional: storage account access tier. It defaults to Hot.')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Optional: environment name (dev | staging | prod). It defaults to dev.')
param environmentName string = 'dev'

@description('Optional: resource display name for the DisplayName resource tag.')
param displayName string = 'Storage Account'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Optional: tags. It is an object.')
param tags object = {
  environment: environmentName
  DisplayName: displayName
  Owner: ownerName
}

@description('Required: name of the virtual network allowed to access the storage account.')
param vnetName string

@description('Required: create new or existing storage account. It defaults to new.')
@allowed([
  'new'
  'existing'
])
param storageAccountNewOrExisting string = 'new'

@description('Required: names of subnets allowed to access the storage account. It is an array of strings.')
param subnets array

@description('Required: Public IP address allowed to access storage account. It defaults to the IP address of the machine running the deployment.')
param publicIpAddress string

resource storageAccountNew 'Microsoft.Storage/storageAccounts@2025-08-01' = if (storageAccountNewOrExisting == 'new' && storageAccountName != '') {
  name: storageAccountName
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
  }
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [for subnet in subnets: {
        id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet)
        action: 'Allow'
      }]
      ipRules: [
        {
          value: publicIpAddress
          action: 'Allow'
        }
      ]
    }
  }
}

resource storageAccountExisting 'Microsoft.Storage/storageAccounts@2025-08-01' existing = if (storageAccountNewOrExisting == 'existing' && storageAccountName != '') {
  name: storageAccountName
}

var resolvedAccountName = storageAccountNewOrExisting == 'new' ? storageAccountNew.name : storageAccountExisting.name

output storageAccountId string = storageAccountNewOrExisting == 'new' ? storageAccountNew.id : storageAccountExisting.id
output storageAccountName string = resolvedAccountName
