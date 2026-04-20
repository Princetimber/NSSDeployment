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

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
}

resource subnetRefs 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' existing = [
  for subnet in subnets: {
    parent: vnet
    name: subnet
  }
]

@description('Required: create new or existing storage account. It defaults to new.')
@allowed([
  'new'
  'existing'
])
param storageAccountNewOrExisting string = 'new'

@description('Required: names of subnets allowed to access the storage account. It is an array of strings.')
@allowed([
  'subnet1'
  'subnet2'
])
param subnets array

@description('Required: Public IP address allowed to access storage account. It defaults to the IP address of the machine running the deployment.')
param publicIpAddress string

@description('Optional: name of the blob container for VHD uploads. Defaults to vhds.')
param vhdContainerName string = 'vhds'

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
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        for (subnet, i) in subnets: {
          id: subnetRefs[i].id
          action: 'Allow'
        }
      ]
      ipRules: [
        {
          value: publicIpAddress
          action: 'Allow'
        }
      ]
    }
    allowBlobPublicAccess: true
    allowCrossTenantReplication: true
    allowSharedKeyAccess: true
    isNfsV3Enabled: false
    isLocalUserEnabled: true
    keyPolicy: {
      keyExpirationPeriodInDays: 90
    }
    immutableStorageWithVersioning: {
      enabled: true
      immutabilityPolicy: {
        immutabilityPeriodSinceCreationInDays: 30
        allowProtectedAppendWrites: true
        state: 'Unlocked'
      }
    }
  }
}

resource storageAccountExisting 'Microsoft.Storage/storageAccounts@2025-08-01' existing = if (storageAccountNewOrExisting == 'existing' && storageAccountName != '') {
  name: storageAccountName
}

resource blobServiceNew 'Microsoft.Storage/storageAccounts/blobServices@2025-08-01' = if (storageAccountNewOrExisting == 'new' && storageAccountName != '') {
  parent: storageAccountNew
  name: 'default'
  properties: {}
}

resource vhdContainerNew 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-08-01' = if (storageAccountNewOrExisting == 'new' && storageAccountName != '') {
  parent: blobServiceNew
  name: vhdContainerName
  properties: {
    publicAccess: 'None'
  }
}

var resolvedAccountName = storageAccountNewOrExisting == 'new' ? storageAccountNew.name : storageAccountExisting.name

output storageAccountId string = storageAccountNewOrExisting == 'new' ? storageAccountNew.id : storageAccountExisting.id
output storageAccountNameOutput string = resolvedAccountName
output vhdContainerName string = vhdContainerName
output vhdContainerUri string = 'https://${resolvedAccountName}.blob.${environment().suffixes.storage}/${vhdContainerName}'
