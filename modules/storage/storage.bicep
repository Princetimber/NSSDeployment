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

@description('Required: name of the virtual network whose subnets are allowed access.')
param vnetName string

@description('Required: subnet names allowed to access the storage account.')
param subnets array

@description('Required: public IP address allowed to access the storage account.')
param publicIpAddress string

// Build the VNet rule list outside the resource to avoid ARM property-iteration
// issues that arise when a for-loop sits inside a conditional resource's properties.
var vnetRules = [for subnet in subnets: {
  id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnet)
  action: 'Allow'
}]

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
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: vnetRules
      ipRules: [
        {
          value: publicIpAddress
          action: 'Allow'
        }
      ]
    }
  }
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
