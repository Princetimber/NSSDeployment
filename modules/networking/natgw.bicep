@description('Required:location of the resource.')
param location string = resourceGroup().location

@description('Required:name of the NAT Gateway.')
param natGatewayName string = 'natgw-${toLower(projectName)}-${toLower(environmentName)}'

@description('Required: name of the public ip address. It defaults to resource name prefixed with pubIp.')
param publicIpName string = '${natGatewayName}pubIp'

@description('Required:name of subnet to deploy the nat gateway in')
param subnets array

@description('Required:environment name (dev | staging | prod).It defaults to dev.')
param environmentName string = 'dev'

@description('Required:project name used as the resource naming infix.')
param projectName string

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Optional: resource display name for the DisplayName resource tag.')
param displayName string = 'NAT Gateway'


@description('Optional: tags. It is an object.')
param tags object = {
  environment: environmentName
  DisplayName: displayName
  Owner: ownerName
}
@description('Required:name of the virtual network to deploy the nat gateway in')
param virtualNetworkName string = 'vnet-${toLower(projectName)}-${toLower(environmentName)}'

@description('Required:name of the network security group to deploy the nat gateway in')
param networkSecurityGroupName string = 'nsg-${toLower(projectName)}-${toLower(environmentName)}'

@description('Required:sku name of the nat gateway. It defaults to Standard.')
param natGatewaySku string = 'Standard'

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' existing = {
  name: networkSecurityGroupName
}
var nsgId = nsg.id

resource vnet 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  name: virtualNetworkName
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2025-05-01' = {
  name: publicIpName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: natGatewaySku
  }
}
resource natgw 'Microsoft.Network/natGateways@2025-05-01' = {
  name: natGatewayName
  location: location
  tags: tags
  properties: {
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: natGatewaySku
  }
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2025-05-01' = [for subnet in subnets: {
  name: subnet.name
  parent: vnet
  properties: {
    addressPrefix: subnet.addressPrefix
    networkSecurityGroup: {
      id: nsgId
    }
    natGateway: {
      id: natgw.id
    }
    defaultOutboundAccess: true

  }
}]
output natGatewayId string = natgw.id
output natGatewayName string = natgw.name
output publicIpId string = publicIp.id
output publicIpName string = publicIp.name
