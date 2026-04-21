// Module : networking
// Purpose: VNets, subnets, NSGs, NAT Gateways, and DNS resources

targetScope = 'resourceGroup'

@description('Azure region.')
param location string = resourceGroup().location

@description('Environment name: dev | staging | prod.')
param environmentName string = 'dev'

@description('Project name used as a resource naming prefix.')
param projectName string

@description('Optional: owner name for the Owner resource tag.')
param ownerName string = ''

@description('Resource tags.')
param tags object = {
  environment: environmentName
  DisplayName: projectName
  Owner: ownerName
}

@description('Required: destination address prefixes for outbound NSG rules. Use the IP ranges supplied by Zscaler.')
param destinationAddressPrefixes array

@description('Required: source address prefixes for outbound NSG rules. Use the subnet CIDR blocks for the VNet.')
param sourceAddressPrefixes array

@description('Required: address prefixes for the virtual network (e.g. [\'10.0.0.0/16\']).')
param addressPrefixes array

@description('Required: subnets to create inside the virtual network.')
param subnets array

@description('Required: DNS servers for the virtual network.')
param dnsServers array

@description('Required: subnets to associate with the NAT Gateway after the VNet is provisioned.')
param natGatewaySubnets array

@description('Required: CIDR of the AzureBastionSubnet — used to scope the Bastion SSH inbound rule.')
param bastionSubnetAddressPrefix string

@description('Whether to deploy Azure Bastion. Set to false when Bastion already exists in the VNet.')
param deployBastion bool = true

// Explicit name keeps nsg.bicep and vnet.bicep (which looks up the NSG as `existing`)
// in sync — both must use the same formula: nsg-<projectName>-<environmentName>.
var nsgName = 'nsg-${toLower(projectName)}-${toLower(environmentName)}'

module nsg 'nsg.bicep' = {
  name: '${projectName}-nsg'
  params: {
    name: nsgName
    location: location
    tags: tags
    destinationAddressPrefixes: destinationAddressPrefixes
    sourceAddressPrefixes: sourceAddressPrefixes
    ownerName: ownerName
    environmentName: environmentName
    bastionSubnetAddressPrefix: bastionSubnetAddressPrefix
  }
}

// vnet.bicep references the NSG by name via `existing`, so Bicep cannot track the
// dependency implicitly — dependsOn ensures NSG is fully deployed before the VNet.
module vnet 'vnet.bicep' = {
  name: '${projectName}-vnet'
  params: {
    location: location
    tags: tags
    projectName: projectName
    environmentName: environmentName
    ownerName: ownerName
    addressPrefixes: addressPrefixes
    subnets: subnets
    dnsServers: dnsServers
  }
  dependsOn: [nsg]
}

// natgw.bicep references both the VNet and NSG by name, so it must wait for both.
// dependsOn vnet is sufficient because vnet already depends on nsg.
module natgw 'natgw.bicep' = {
  name: '${projectName}-natgw'
  params: {
    location: location
    tags: tags
    projectName: projectName
    environmentName: environmentName
    ownerName: ownerName
    subnets: natGatewaySubnets
  }
  dependsOn: [vnet]
}

module bastion 'bastion.bicep' = if (deployBastion) {
  name: '${projectName}-bastion'
  params: {
    location: location
    environmentName: environmentName
    projectName: projectName
    tags: tags
  }
  dependsOn: [vnet]
}

output nsgId string = nsg.outputs.nsgId
output nsgName string = nsg.outputs.nsgName
output vnetId string = vnet.outputs.id
output vnetName string = vnet.outputs.name
output natGatewayId string = natgw.outputs.natGatewayId
output natGatewayName string = natgw.outputs.natGatewayName
output publicIpId string = natgw.outputs.publicIpId
output publicIpName string = natgw.outputs.publicIpName
output bastionId string = deployBastion ? bastion!.outputs.bastionId : ''
output bastionName string = deployBastion ? bastion!.outputs.bastionName : ''
