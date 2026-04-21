@description('Required:network security group location')
param location string = resourceGroup().location

@description('Required:name of the network security group to create.This must be unique within the resource group and can not be changed after creation. It defaults to the resource group name prefixed with nsg.')
param name string = '${toLower(replace(resourceGroup().name, 'enguksouthrg', '-'))}nsg'

@description('Required: source address prefixes, which includes the IP address range or CIDR block for the source of the rule. This can be internet, virtual network, subnet, or IP address or Public IP Address based on the service.')
param sourceAddressPrefixes array

@description('Required: destination address prefix. This can also be a CIDR block, virtual network, or service tag or Ip Address based on the service.')
param destinationAddressPrefixes array

@description('Optional: environment name for the Environment resource tag.')
param environmentName string = 'Dev'

@description('Optional: owner name for the Owner resource tag.')
param ownerName string

@description('Required: CIDR of the AzureBastionSubnet — used to scope the Bastion SSH inbound rule.')
param bastionSubnetAddressPrefix string

@description('Optional:tags of the network security group to create.')
param tags object = {
  displayName: 'Network Security Group'
  Environment: environmentName
  Owner: ownerName
}
//Inbound security rule collection

var securityRules = [
  {
    name: 'Allow-Azure-SSH-Bastion'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: bastionSubnetAddressPrefix
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '22'
      description: 'Allow inbound SSH from Azure Bastion subnet'
    }
  }
  {
    name: 'Allow-SSH-Mgmt'
    properties: {
      priority: 110
      direction: 'Inbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '10.2.1.0/24'
      destinationPortRange: '22'
      description: 'Allow inbound SSH traffic'
    }
  }
  {
    name: 'Allow-HTTPS-ZscalerHub'
    properties: {
      priority: 120
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefixes: destinationAddressPrefixes
      destinationPortRange: '443'
      description: 'Allow outbound traffic to NSS Zscaler Hub'
    }
  }
  {
    name:'Allow-Zscaler-RemoteSupport'
    properties: {
      priority: 130
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefix:'199.168.148.101'
      destinationPortRange: '12002'
      description: 'Allow outbound traffic to Zscaler Remote Support'
    }
  }
  {
    name:'Allow-DNS'
    properties: {
      priority: 140
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '53'
      description: 'Allow outbound DNS traffic'
    }
  }
  {
    name:'Allow-NTP'
    properties: {
      priority: 150
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '123'
      description: 'Allow outbound NTP traffic'
    }
  }
  {
    name:'Allow-ICMP'
    properties: {
      priority: 160
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Icmp'
      sourceAddressPrefixes: sourceAddressPrefixes
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
      description: 'Allow outbound ICMP traffic'
    }
  }
]

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules:[
      for rule in securityRules: {
        name: rule.name
        properties: rule.properties
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
