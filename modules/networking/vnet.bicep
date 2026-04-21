/*
  This Bicep file defines a virtual network (VNet) in Azure. It includes parameters for the VNet name, address space, and tags. The NSG (Network Security Group) lives in the sibling `nsg.bicep` file in this module directory.
*/

@description('Required: resource location. It defaults to the resource group location.')
param location string = resourceGroup().location

@description('Required: environment name (dev | staging | prod).')
param environmentName string

@description('Required: project name used as the resource naming infix.')
param projectName string

@description('Required: virtual network resource name.')
param vnetName string = 'vnet-${toLower(projectName)}-${toLower(environmentName)}'

@description('Required: network security group resource name.')
param nsgName string = 'nsg-${toLower(projectName)}-${toLower(environmentName)}'

@description('Required: virtual network address prefixes. It is an array of strings.')
param addressPrefixes array

@description('Required: virtual network subnets. It is an array of objects.')
param subnets array

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Optional: environment tag value (dev | staging | prod). It defaults to dev.')
param environmentTag string = 'dev'

@description('Optional: display name for the DisplayName resource tag.')
param displayName string = 'Virtual Network'

@description('Optional: tags. It is an object.')
param tags object = {
  environment: environmentTag
  DisplayName: displayName
  Owner: ownerName
}
@description('Optional: DNS servers. It is an array of strings.')
param dnsServers array

@description('Required: create new or existing virtual network. It defaults to new.')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' existing = {
  name: nsgName
}
var nsgId = nsg.id

resource vnetNew 'Microsoft.Network/virtualNetworks@2025-05-01' = if(vnetNewOrExisting == 'new'){
  name: vnetName
  location:location
  tags: tags
  properties:{
    addressSpace:{
      addressPrefixes: addressPrefixes
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsgId
        }
        // Required for storage account VNet firewall rules to accept this subnet
        serviceEndpoints: [
          { service: 'Microsoft.Storage' }
        ]
      }
    }]
    enableDdosProtection: false
    dhcpOptions: {
      dnsServers: dnsServers
    }
  }
}
resource vnetExisting 'Microsoft.Network/virtualNetworks@2025-05-01' existing = if(vnetNewOrExisting == 'existing'){
  name: vnetName
}

output name string = vnetNewOrExisting == 'new' ? vnetNew.name : vnetExisting.name
output id string = vnetNewOrExisting == 'new' ? vnetNew.id : vnetExisting.id
