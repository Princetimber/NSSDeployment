@description('Required: resource location.')
param location string = resourceGroup().location

@description('Required: environment name (dev | staging | prod).')
param environmentName string

@description('Required: project name used as the resource naming infix.')
param projectName string

@description('Optional: resource tags.')
param tags object = {}

var bastionName = 'bas-${toLower(projectName)}-${toLower(environmentName)}'
var pipName     = 'pip-bastion-${toLower(projectName)}-${toLower(environmentName)}'
var vnetName    = 'vnet-${toLower(projectName)}-${toLower(environmentName)}'

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: vnetName
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' existing = {
  parent: vnet
  name: 'AzureBastionSubnet'
}

resource pip 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: pipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2025-05-01' = {
  name: bastionName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: pip.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

output bastionId   string = bastion.id
output bastionName string = bastion.name
